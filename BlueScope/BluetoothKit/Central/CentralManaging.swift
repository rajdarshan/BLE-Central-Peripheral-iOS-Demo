import Foundation
import Combine

/// The only surface a view model should ever see for central-role BLE work.
/// CentralManager (real, wraps CBCentralManager) and MockCentralManager
/// (fake, for tests/previews) both conform to this — nothing above this
/// layer ever names CBPeripheral, CBCharacteristic, or CBUUID directly.
@MainActor
protocol CentralManaging: AnyObject {
    var statePublisher: AnyPublisher<BluetoothState, Never> { get }
    var discoveredPeripheralsPublisher: AnyPublisher<[DiscoveredPeripheral], Never> { get }
    var connectionStatePublisher: AnyPublisher<ConnectionState, Never> { get }
    /// Fires once a peripheral CoreBluetooth handed back via state restoration
    /// (willRestoreState) has finished reconnecting — first characteristics
    /// discovered, matching the same threshold ConnectionState.connected uses
    /// elsewhere. Lets the UI navigate straight to that device's detail
    /// screen without the caller needing to know restoration even happened.
    var restoredConnectionPublisher: AnyPublisher<DiscoveredPeripheral, Never> { get }

    func startScanning()
    func stopScanning()

    func connect(to peripheralID: UUID) async throws
    func disconnect() async

    func readValue(for characteristicID: String) async throws -> CharacteristicValue
    func writeValue(_ data: Data, for characteristicID: String) async throws
    func setNotifications(_ enabled: Bool, for characteristicID: String) async throws

    /// Called by RoleManager when switching away from central role.
    func tearDown()
}
