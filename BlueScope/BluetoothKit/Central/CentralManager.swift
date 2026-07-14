import CoreBluetooth
import Combine

/// Wraps CBCentralManager and its two delegate protocols. This file is the
/// translation boundary: CoreBluetooth types (CBPeripheral, CBCharacteristic,
/// CBUUID, [String: Any] advertisement dictionaries) live and die here.
/// Everything that leaves this class is a BluetoothKit domain type.
///
/// Delegate methods are `nonisolated` (required by the ObjC protocols) and
/// hop onto the main actor via `Task { @MainActor in ... }` before touching
/// any state, so all mutation stays serialized on one actor.
@MainActor
final class CentralManager: NSObject, CentralManaging {

    private var manager: CBCentralManager!

    private var discovered: [UUID: DiscoveredPeripheral] = [:]
    // First-seen order, kept stable across updates. Publishing in this order
    // (rather than re-sorting by RSSI on every advertisement) means existing
    // rows never swap places as signal strength wobbles — new devices simply
    // append to the end.
    private var discoveryOrder: [UUID] = []
    private var cbPeripheralsByID: [UUID: CBPeripheral] = [:]
    private var connectedPeripheral: CBPeripheral?
    private var servicesByID: [CBUUID: DiscoveredService] = [:]
    private var characteristicsByUUID: [CBUUID: CBCharacteristic] = [:]

    private let stateSubject = CurrentValueSubject<BluetoothState, Never>(.unknown)
    private let peripheralsSubject = CurrentValueSubject<[DiscoveredPeripheral], Never>([])
    private let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)

    // One-shot request bridges: CoreBluetooth answers via delegate callback,
    // continuation turns that into a normal `try await` for callers.
    private var connectContinuation: CheckedContinuation<Void, Error>?
    private var readContinuations: [CBUUID: CheckedContinuation<CharacteristicValue, Error>] = [:]
    private var writeContinuations: [CBUUID: CheckedContinuation<Void, Error>] = [:]
    private var notifyContinuations: [CBUUID: CheckedContinuation<Void, Error>] = [:]

    var statePublisher: AnyPublisher<BluetoothState, Never> { stateSubject.eraseToAnyPublisher() }

    // Scanning with allow-duplicates delivers a didDiscover callback for every
    // single advertisement (multiple times per second per device), each
    // triggering a re-sort by RSSI. Publishing every one of those to the UI
    // makes the scan list constantly reorder itself — throttled here so rows
    // settle into a stable order instead of flickering.
    var discoveredPeripheralsPublisher: AnyPublisher<[DiscoveredPeripheral], Never> {
        peripheralsSubject
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()
    }

    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> { connectionStateSubject.eraseToAnyPublisher() }

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    func startScanning() {
        guard manager.state == .poweredOn else { return }
        discovered.removeAll()
        discoveryOrder.removeAll()
        peripheralsSubject.send([])
        manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScanning() {
        manager.stopScan()
    }

    func connect(to peripheralID: UUID) async throws {
        guard let cbPeripheral = cbPeripheralsByID[peripheralID] else {
            throw BLEError.peripheralNotFound
        }
        connectionStateSubject.send(.connecting)
        try await withCheckedThrowingContinuation { continuation in
            self.connectContinuation = continuation
            self.manager.connect(cbPeripheral, options: nil)
        }
    }

    func disconnect() async {
        guard let peripheral = connectedPeripheral else { return }
        manager.cancelPeripheralConnection(peripheral)
        connectedPeripheral = nil
        servicesByID.removeAll()
        characteristicsByUUID.removeAll()
        connectionStateSubject.send(.disconnected)
    }

    func readValue(for characteristicID: String) async throws -> CharacteristicValue {
        guard let peripheral = connectedPeripheral,
              let characteristic = characteristicsByUUID[CBUUID(string: characteristicID)] else {
            throw BLEError.readFailed("Characteristic not found")
        }
        return try await withCheckedThrowingContinuation { continuation in
            self.readContinuations[characteristic.uuid] = continuation
            peripheral.readValue(for: characteristic)
        }
    }

    func writeValue(_ data: Data, for characteristicID: String) async throws {
        guard let peripheral = connectedPeripheral,
              let characteristic = characteristicsByUUID[CBUUID(string: characteristicID)] else {
            throw BLEError.writeFailed("Characteristic not found")
        }
        try await withCheckedThrowingContinuation { continuation in
            self.writeContinuations[characteristic.uuid] = continuation
            peripheral.writeValue(data, for: characteristic, type: .withResponse)
        }
    }

    func setNotifications(_ enabled: Bool, for characteristicID: String) async throws {
        guard let peripheral = connectedPeripheral,
              let characteristic = characteristicsByUUID[CBUUID(string: characteristicID)] else {
            throw BLEError.notSubscribable
        }
        guard characteristic.properties.contains(.notify) else {
            throw BLEError.notSubscribable
        }
        try await withCheckedThrowingContinuation { continuation in
            self.notifyContinuations[characteristic.uuid] = continuation
            peripheral.setNotifyValue(enabled, for: characteristic)
        }
    }

    func tearDown() {
        stopScanning()
        if let peripheral = connectedPeripheral {
            manager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        discovered.removeAll()
        discoveryOrder.removeAll()
        cbPeripheralsByID.removeAll()
        servicesByID.removeAll()
        characteristicsByUUID.removeAll()
    }

    @MainActor
    private func updateLatestValue(_ value: CharacteristicValue, for uuid: CBUUID) {
        for (serviceID, var service) in servicesByID {
            if let index = service.characteristics.firstIndex(where: { $0.id == uuid }) {
                service.characteristics[index].latestValue = value
                servicesByID[serviceID] = service
                connectionStateSubject.send(.connected(services: Array(servicesByID.values)))
                return
            }
        }
    }
}

// MARK: - CBCentralManagerDelegate

extension CentralManager: CBCentralManagerDelegate {

    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            self.stateSubject.send(BluetoothState(central.state))
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        Task { @MainActor in
            self.cbPeripheralsByID[peripheral.identifier] = peripheral
            let isConnectable = (advertisementData[CBAdvertisementDataIsConnectable] as? Bool) ?? true
            let entry = DiscoveredPeripheral(
                id: peripheral.identifier,
                name: peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String,
                rssi: RSSI.intValue,
                lastSeen: Date(),
                isConnectable: isConnectable
            )
            if self.discovered[entry.id] == nil {
                self.discoveryOrder.append(entry.id)
            }
            self.discovered[entry.id] = entry
            self.peripheralsSubject.send(self.discoveryOrder.compactMap { self.discovered[$0] })
        }
    }

    nonisolated func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            self.connectedPeripheral = peripheral
            peripheral.delegate = self
            self.connectionStateSubject.send(.discoveringServices)
            peripheral.discoverServices(nil)
            self.connectContinuation?.resume()
            self.connectContinuation = nil
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            let bleError = BLEError.connectionFailed(error?.localizedDescription ?? "Unknown error")
            self.connectionStateSubject.send(.failed(bleError))
            self.connectContinuation?.resume(throwing: bleError)
            self.connectContinuation = nil
        }
    }

    nonisolated func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        Task { @MainActor in
            self.connectedPeripheral = nil
            self.servicesByID.removeAll()
            self.characteristicsByUUID.removeAll()
            self.connectionStateSubject.send(.disconnected)
        }
    }
}

// MARK: - CBPeripheralDelegate

extension CentralManager: CBPeripheralDelegate {

    nonisolated func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        Task { @MainActor in
            if let error {
                self.connectionStateSubject.send(.failed(.serviceDiscoveryFailed(error.localizedDescription)))
                return
            }
            for service in peripheral.services ?? [] {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                self.connectionStateSubject.send(.failed(.characteristicDiscoveryFailed(error.localizedDescription)))
                return
            }
            let discoveredChars = (service.characteristics ?? []).map { cbChar -> DiscoveredCharacteristic in
                self.characteristicsByUUID[cbChar.uuid] = cbChar
                return DiscoveredCharacteristic(
                    id: cbChar.uuid,
                    name: cbChar.uuid.friendlyName,
                    properties: CharacteristicProperties(cbChar.properties),
                    latestValue: nil
                )
            }
            let discoveredService = DiscoveredService(
                id: service.uuid,
                name: service.uuid.friendlyName,
                characteristics: discoveredChars
            )
            self.servicesByID[service.uuid] = discoveredService
            self.connectionStateSubject.send(.connected(services: Array(self.servicesByID.values)))
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                self.readContinuations[characteristic.uuid]?.resume(throwing: BLEError.readFailed(error.localizedDescription))
                self.readContinuations[characteristic.uuid] = nil
                return
            }
            let value = CharacteristicValue(data: characteristic.value ?? Data())
            self.updateLatestValue(value, for: characteristic.uuid)

            if let continuation = self.readContinuations[characteristic.uuid] {
                continuation.resume(returning: value)
                self.readContinuations[characteristic.uuid] = nil
            }
            // No waiting continuation means this update arrived from a notify
            // subscription instead of an explicit read — updateLatestValue above
            // is how that reaches the UI, via the connected-services snapshot.
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            if let error {
                self.writeContinuations[characteristic.uuid]?.resume(throwing: BLEError.writeFailed(error.localizedDescription))
            } else {
                self.writeContinuations[characteristic.uuid]?.resume()
            }
            self.writeContinuations[characteristic.uuid] = nil
        }
    }

    nonisolated func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateNotificationStateFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        Task { @MainActor in
            if error != nil {
                self.notifyContinuations[characteristic.uuid]?.resume(throwing: BLEError.notSubscribable)
            } else {
                self.notifyContinuations[characteristic.uuid]?.resume()
            }
            self.notifyContinuations[characteristic.uuid] = nil
        }
    }
}
