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
/// Restoration identifier passed to CBCentralManager so CoreBluetooth can
/// relaunch the app and hand connected/connecting peripherals back via
/// willRestoreState after the system terminates it while a connection is
/// active. Requires the bluetooth-central UIBackgroundMode to be declared.
private enum RestorationIdentifiers {
    static let central = "com.rajdarshan.BlueScope.central-manager"
}

@MainActor
final class CentralManager: NSObject, CentralManaging {

    private var manager: CBCentralManager!

    /// Bounded exponential backoff applied after an unexpected disconnect
    /// (didDisconnectPeripheral firing with a non-nil error). A deliberate
    /// disconnect() call never reaches this path.
    static let maxReconnectAttempts = 4

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

    private var reconnectTask: Task<Void, Never>?
    private var reconnectAttempt = 0
    private var isDeliberateDisconnect = false

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
        manager = CBCentralManager(
            delegate: self,
            queue: nil,
            options: [CBCentralManagerOptionRestoreIdentifierKey: RestorationIdentifiers.central]
        )
    }

    /// Delay before reconnect attempt `attempt` (1-indexed): 1, 2, 4, 8s.
    /// A pure function so the backoff curve is unit-testable without CoreBluetooth.
    static func backoffDelay(forAttempt attempt: Int) -> Duration {
        .seconds(pow(2.0, Double(min(attempt, maxReconnectAttempts) - 1)))
    }

    func startScanning() {
        guard manager.state == .poweredOn else { return }
        discovered.removeAll()
        discoveryOrder.removeAll()
        peripheralsSubject.send([])
        manager.scanForPeripherals(withServices: nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }

    func stopScanning() {
        guard manager.state == .poweredOn else { return }
        manager.stopScan()
    }

    func connect(to peripheralID: UUID) async throws {
        guard let cbPeripheral = cbPeripheralsByID[peripheralID] else {
            throw BLEError.peripheralNotFound
        }
        connectionStateSubject.send(.connecting)
        try await waitForPoweredOn()
        try await withCheckedThrowingContinuation { continuation in
            self.connectContinuation = continuation
            self.manager.connect(cbPeripheral, options: nil)
        }
    }

    func disconnect() async {
        reconnectTask?.cancel()
        reconnectTask = nil
        guard let peripheral = connectedPeripheral else { return }
        isDeliberateDisconnect = true
        if manager.state == .poweredOn {
            manager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        servicesByID.removeAll()
        characteristicsByUUID.removeAll()
        connectionStateSubject.send(.disconnected)
    }

    /// Suspends until the manager reports `.poweredOn`, so a command issued
    /// right after a CoreBluetooth-triggered relaunch (state restoration)
    /// doesn't race the manager's first state update — the only other
    /// caller of CBCentralManager commands, startScanning(), sidesteps this
    /// by silently no-op'ing instead, which connect() can't do since it's
    /// awaited by the reconnect-on-drop loop.
    private func waitForPoweredOn() async throws {
        for await state in statePublisher.values {
            if state == .poweredOn { return }
            if state == .unauthorized || state == .unsupported {
                throw BLEError.bluetoothUnavailable(state)
            }
        }
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
        reconnectTask?.cancel()
        reconnectTask = nil
        reconnectAttempt = 0
        if manager.state == .poweredOn, let peripheral = connectedPeripheral {
            manager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        discovered.removeAll()
        discoveryOrder.removeAll()
        cbPeripheralsByID.removeAll()
        servicesByID.removeAll()
        characteristicsByUUID.removeAll()
        connectionStateSubject.send(.disconnected)
    }

    private func beginReconnect(to peripheralID: UUID, reason: String) {
        reconnectAttempt = 0
        reconnectTask?.cancel()
        reconnectTask = Task { [weak self] in
            await self?.attemptReconnect(peripheralID: peripheralID, reason: reason)
        }
    }

    private func attemptReconnect(peripheralID: UUID, reason: String) async {
        while reconnectAttempt < Self.maxReconnectAttempts {
            reconnectAttempt += 1
            connectionStateSubject.send(.reconnecting(attempt: reconnectAttempt, maxAttempts: Self.maxReconnectAttempts))
            try? await Task.sleep(for: Self.backoffDelay(forAttempt: reconnectAttempt))
            guard !Task.isCancelled else { return }
            do {
                try await connect(to: peripheralID)
                reconnectAttempt = 0
                return
            } catch {
                continue
            }
        }
        guard !Task.isCancelled else { return }
        connectionStateSubject.send(.reconnectFailed(.disconnected(reason)))
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
            let wasDeliberate = self.isDeliberateDisconnect
            self.isDeliberateDisconnect = false
            self.connectedPeripheral = nil
            self.servicesByID.removeAll()
            self.characteristicsByUUID.removeAll()

            if let error, !wasDeliberate {
                self.beginReconnect(to: peripheral.identifier, reason: error.localizedDescription)
            } else {
                self.connectionStateSubject.send(.disconnected)
            }
        }
    }

    // Verified manually only: a genuine cold-relaunch triggered by
    // CoreBluetooth (kill the app, drop/hold a connection while suspended,
    // observe the system relaunch it) requires two physical devices and
    // cannot be exercised in XCTest — CBPeripheral has no public initializer.
    nonisolated func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        Task { @MainActor in
            guard let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] else { return }
            for peripheral in peripherals {
                self.cbPeripheralsByID[peripheral.identifier] = peripheral
                peripheral.delegate = self
                switch peripheral.state {
                case .connected:
                    self.connectedPeripheral = peripheral
                    self.connectionStateSubject.send(.discoveringServices)
                    do {
                        // willRestoreState can fire before this fresh
                        // CBCentralManager has delivered its first
                        // centralManagerDidUpdateState(.poweredOn) — issuing
                        // discoverServices() before that is what produced the
                        // "API MISUSE: ... powered on state" warning.
                        try await self.waitForPoweredOn()
                        peripheral.discoverServices(nil)
                    } catch {
                        self.connectionStateSubject.send(.failed(.serviceDiscoveryFailed(error.localizedDescription)))
                    }
                case .connecting:
                    self.connectedPeripheral = peripheral
                    self.connectionStateSubject.send(.connecting)
                default:
                    break
                }
            }
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
