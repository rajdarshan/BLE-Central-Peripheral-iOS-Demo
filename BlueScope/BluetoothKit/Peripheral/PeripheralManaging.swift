import Foundation
import Combine

/// The only surface a view model should ever see for peripheral-role BLE work.
/// Mirrors CentralManaging's shape on purpose — same pattern on both sides of
/// the role split keeps the two feature modules easy to reason about together.
@MainActor
protocol PeripheralManaging: AnyObject {
    var statePublisher: AnyPublisher<BluetoothState, Never> { get }
    var isAdvertisingPublisher: AnyPublisher<Bool, Never> { get }
    var connectedCentralsPublisher: AnyPublisher<[ConnectedCentral], Never> { get }
    var requestLogPublisher: AnyPublisher<[CentralRequestLogEntry], Never> { get }

    func startAdvertising(localName: String)
    func stopAdvertising()
    func pushValue(_ data: Data)

    /// Called by RoleManager when switching away from peripheral role.
    func tearDown()
}
