import Foundation
import Combine
@testable import BlueScope

/// A fake conforming to PeripheralManaging. Mirrors MockCentralManager's
/// shape: expose the subjects as `let` so a test can drive state directly,
/// and record calls so assertions don't have to re-implement CoreBluetooth
/// behavior.
@MainActor
final class MockPeripheralManager: PeripheralManaging {

    let stateSubject = CurrentValueSubject<BluetoothState, Never>(.poweredOn)
    let advertisingSubject = CurrentValueSubject<Bool, Never>(false)
    let centralsSubject = CurrentValueSubject<[ConnectedCentral], Never>([])
    let logSubject = CurrentValueSubject<[CentralRequestLogEntry], Never>([])

    var statePublisher: AnyPublisher<BluetoothState, Never> { stateSubject.eraseToAnyPublisher() }
    var isAdvertisingPublisher: AnyPublisher<Bool, Never> { advertisingSubject.eraseToAnyPublisher() }
    var connectedCentralsPublisher: AnyPublisher<[ConnectedCentral], Never> { centralsSubject.eraseToAnyPublisher() }
    var requestLogPublisher: AnyPublisher<[CentralRequestLogEntry], Never> { logSubject.eraseToAnyPublisher() }

    // Recorded calls — assert against these instead of re-implementing CoreBluetooth behavior.
    private(set) var didStartAdvertising = false
    private(set) var didTearDown = false
    private(set) var advertisedLocalName: String?
    private(set) var pushedValues: [Data] = []

    func startAdvertising(localName: String) {
        advertisedLocalName = localName
        didStartAdvertising = true
        advertisingSubject.send(true)
    }

    func stopAdvertising() {
        didStartAdvertising = false
        advertisingSubject.send(false)
    }

    func pushValue(_ data: Data) {
        pushedValues.append(data)
    }

    func tearDown() {
        didTearDown = true
        didStartAdvertising = false
        advertisingSubject.send(false)
        centralsSubject.send([])
    }
}
