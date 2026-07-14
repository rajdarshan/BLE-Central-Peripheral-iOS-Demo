import Foundation
import Combine
@testable import BlueScope

/// A fake conforming to CentralManaging. ScanViewModel / DeviceDetailViewModel
/// tests inject this instead of the real CentralManager, so tests run on
/// CI and in Simulator without any physical Bluetooth hardware involved.
///
/// Pattern: expose the subjects as `let`, not just the publishers, so a test
/// can drive the fake's state directly (`mock.peripheralsSubject.send([...])`)
/// to simulate "three devices appeared" without touching CoreBluetooth at all.
@MainActor
final class MockCentralManager: CentralManaging {

    let stateSubject = CurrentValueSubject<BluetoothState, Never>(.poweredOn)
    let peripheralsSubject = CurrentValueSubject<[DiscoveredPeripheral], Never>([])
    let connectionStateSubject = CurrentValueSubject<ConnectionState, Never>(.disconnected)

    var statePublisher: AnyPublisher<BluetoothState, Never> { stateSubject.eraseToAnyPublisher() }
    var discoveredPeripheralsPublisher: AnyPublisher<[DiscoveredPeripheral], Never> { peripheralsSubject.eraseToAnyPublisher() }
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> { connectionStateSubject.eraseToAnyPublisher() }

    // Recorded calls — assert against these instead of re-implementing CoreBluetooth behavior.
    private(set) var didStartScanning = false
    private(set) var didStopScanning = false
    private(set) var connectedPeripheralID: UUID?

    // Configure before the call under test to control what happens.
    var connectError: BLEError?
    var readResult: Result<CharacteristicValue, BLEError> = .success(CharacteristicValue(data: Data([0x00])))
    var writeError: BLEError?
    var notifyError: BLEError?

    func startScanning() {
        didStartScanning = true
    }

    func stopScanning() {
        didStartScanning = false
        didStopScanning = true
    }

    func connect(to peripheralID: UUID) async throws {
        if let connectError { throw connectError }
        connectedPeripheralID = peripheralID
        connectionStateSubject.send(.connected(services: []))
    }

    func disconnect() async {
        connectedPeripheralID = nil
        connectionStateSubject.send(.disconnected)
    }

    func readValue(for characteristicID: String) async throws -> CharacteristicValue {
        try readResult.get()
    }

    func writeValue(_ data: Data, for characteristicID: String) async throws {
        if let writeError { throw writeError }
    }

    func setNotifications(_ enabled: Bool, for characteristicID: String) async throws {
        if let notifyError { throw notifyError }
    }

    func tearDown() {
        didStartScanning = false
        connectedPeripheralID = nil
        peripheralsSubject.send([])
        connectionStateSubject.send(.disconnected)
    }
}
