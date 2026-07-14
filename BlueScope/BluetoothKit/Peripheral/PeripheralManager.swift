import CoreBluetooth
import Combine

/// Wraps CBPeripheralManager. Same translation-boundary role as CentralManager
/// plays on the other side: CBCentral, CBATTRequest, and CBMutableCharacteristic
/// live and die in this file. Everything published outward is a domain type.
///
/// Delegate methods are `nonisolated` and hop to the main actor via `Task`,
/// matching CentralManager's pattern so state mutation stays single-threaded.
@MainActor
final class PeripheralManager: NSObject, PeripheralManaging {

    private var manager: CBPeripheralManager!
    private var mutableCharacteristic: CBMutableCharacteristic?
    private var pendingLocalName: String?
    private var currentValue = Data([0x00])
    private var subscribed: [UUID: ConnectedCentral] = [:]

    private let stateSubject = CurrentValueSubject<BluetoothState, Never>(.unknown)
    private let advertisingSubject = CurrentValueSubject<Bool, Never>(false)
    private let centralsSubject = CurrentValueSubject<[ConnectedCentral], Never>([])
    private let logSubject = CurrentValueSubject<[CentralRequestLogEntry], Never>([])

    var statePublisher: AnyPublisher<BluetoothState, Never> { stateSubject.eraseToAnyPublisher() }
    var isAdvertisingPublisher: AnyPublisher<Bool, Never> { advertisingSubject.eraseToAnyPublisher() }
    var connectedCentralsPublisher: AnyPublisher<[ConnectedCentral], Never> { centralsSubject.eraseToAnyPublisher() }
    var requestLogPublisher: AnyPublisher<[CentralRequestLogEntry], Never> { logSubject.eraseToAnyPublisher() }

    override init() {
        super.init()
        manager = CBPeripheralManager(delegate: self, queue: nil)
    }

    func startAdvertising(localName: String) {
        pendingLocalName = localName
        guard manager.state == .poweredOn else { return } // resumes from peripheralManagerDidUpdateState once ready
        let service = MockGATTService.makeCBService()
        mutableCharacteristic = service.characteristics?.first as? CBMutableCharacteristic
        manager.removeAllServices()
        manager.add(service)
        manager.startAdvertising([
            CBAdvertisementDataLocalNameKey: localName,
            CBAdvertisementDataServiceUUIDsKey: [MockGATTService.serviceUUID]
        ])
    }

    func stopAdvertising() {
        manager.stopAdvertising()
        advertisingSubject.send(false)
    }

    func pushValue(_ data: Data) {
        currentValue = data
        guard let characteristic = mutableCharacteristic else { return }
        let delivered = manager.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
        appendLog(
            centralID: nil,
            message: delivered ? "Pushed \(data.count) bytes to subscribers" : "Push queued — will retry when the transmit queue frees up"
        )
    }

    func tearDown() {
        stopAdvertising()
        manager.removeAllServices()
        subscribed.removeAll()
        centralsSubject.send([])
    }

    private func appendLog(centralID: UUID?, message: String) {
        var log = logSubject.value
        log.append(CentralRequestLogEntry(timestamp: Date(), centralID: centralID ?? UUID(), message: message))
        logSubject.send(Array(log.suffix(50))) // cap so a long demo session doesn't grow this unbounded
    }
}

// MARK: - CBPeripheralManagerDelegate

extension PeripheralManager: CBPeripheralManagerDelegate {

    nonisolated func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        Task { @MainActor in
            self.stateSubject.send(BluetoothState(peripheral.state))
            if peripheral.state == .poweredOn, let name = self.pendingLocalName {
                self.startAdvertising(localName: name)
            }
        }
    }

    nonisolated func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        Task { @MainActor in
            self.advertisingSubject.send(error == nil)
        }
    }

    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didSubscribeTo characteristic: CBCharacteristic
    ) {
        Task { @MainActor in
            self.subscribed[central.identifier] = ConnectedCentral(id: central.identifier, isSubscribed: true, lastActivity: Date())
            self.centralsSubject.send(Array(self.subscribed.values))
            self.appendLog(centralID: central.identifier, message: "Central subscribed")
        }
    }

    nonisolated func peripheralManager(
        _ peripheral: CBPeripheralManager,
        central: CBCentral,
        didUnsubscribeFrom characteristic: CBCharacteristic
    ) {
        Task { @MainActor in
            self.subscribed[central.identifier] = nil
            self.centralsSubject.send(Array(self.subscribed.values))
            self.appendLog(centralID: central.identifier, message: "Central unsubscribed")
        }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        Task { @MainActor in
            request.value = self.currentValue
            peripheral.respond(to: request, withResult: .success)
            self.appendLog(centralID: request.central.identifier, message: "Central read value")
        }
    }

    nonisolated func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        Task { @MainActor in
            for request in requests {
                if let value = request.value {
                    self.currentValue = value
                    self.appendLog(centralID: request.central.identifier, message: "Central wrote \(value.count) bytes")
                }
                peripheral.respond(to: request, withResult: .success)
            }
        }
    }
}
