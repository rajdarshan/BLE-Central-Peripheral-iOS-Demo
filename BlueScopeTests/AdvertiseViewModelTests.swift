import XCTest
import Combine
@testable import BlueScope

@MainActor
final class AdvertiseViewModelTests: XCTestCase {

    func test_isAdvertising_reflectsManagerPublisher() {
        let mock = MockPeripheralManager()
        let viewModel = AdvertiseViewModel(peripheralManager: mock)

        mock.advertisingSubject.send(true)
        XCTAssertTrue(viewModel.isAdvertising)

        mock.advertisingSubject.send(false)
        XCTAssertFalse(viewModel.isAdvertising)
    }

    func test_bluetoothState_reflectsManagerPublisher() {
        let mock = MockPeripheralManager()
        let viewModel = AdvertiseViewModel(peripheralManager: mock)

        mock.stateSubject.send(.poweredOff)
        XCTAssertEqual(viewModel.bluetoothState, .poweredOff)
    }

    func test_start_startsAdvertisingWithLocalName() {
        let mock = MockPeripheralManager()
        let viewModel = AdvertiseViewModel(peripheralManager: mock)

        viewModel.start()

        XCTAssertTrue(mock.didStartAdvertising)
        XCTAssertEqual(mock.advertisedLocalName, "BlueScope")
    }

    func test_stop_stopsAdvertising() {
        let mock = MockPeripheralManager()
        let viewModel = AdvertiseViewModel(peripheralManager: mock)
        viewModel.start()

        viewModel.stop()

        XCTAssertFalse(mock.didStartAdvertising)
        XCTAssertFalse(viewModel.isAdvertising)
    }
}
