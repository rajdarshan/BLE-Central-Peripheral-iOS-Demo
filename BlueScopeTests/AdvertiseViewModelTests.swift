import XCTest
import Combine
@testable import BlueScope

@MainActor
final class AdvertiseViewModelTests: XCTestCase {

    func test_isAdvertising_reflectsManagerPublisher() {
        let mock = MockPeripheralManager()
        let viewModel = AdvertiseViewModel(peripheralManager: mock, localNameStore: MockLocalNameStore())

        mock.advertisingSubject.send(true)
        XCTAssertTrue(viewModel.isAdvertising)

        mock.advertisingSubject.send(false)
        XCTAssertFalse(viewModel.isAdvertising)
    }

    func test_bluetoothState_reflectsManagerPublisher() {
        let mock = MockPeripheralManager()
        let viewModel = AdvertiseViewModel(peripheralManager: mock, localNameStore: MockLocalNameStore())

        mock.stateSubject.send(.poweredOff)
        XCTAssertEqual(viewModel.bluetoothState, .poweredOff)
    }

    func test_start_startsAdvertisingWithLocalName() {
        let mock = MockPeripheralManager()
        let viewModel = AdvertiseViewModel(peripheralManager: mock, localNameStore: MockLocalNameStore())

        viewModel.start()

        XCTAssertTrue(mock.didStartAdvertising)
        XCTAssertEqual(mock.advertisedLocalName, "BlueScope")
    }

    func test_stop_stopsAdvertising() {
        let mock = MockPeripheralManager()
        let viewModel = AdvertiseViewModel(peripheralManager: mock, localNameStore: MockLocalNameStore())
        viewModel.start()

        viewModel.stop()

        XCTAssertFalse(mock.didStartAdvertising)
        XCTAssertFalse(viewModel.isAdvertising)
    }

    func test_init_loadsStoredLocalName() {
        let mock = MockPeripheralManager()
        let store = MockLocalNameStore()
        store.storedName = "Kitchen Echo"

        let viewModel = AdvertiseViewModel(peripheralManager: mock, localNameStore: store)

        XCTAssertEqual(viewModel.localName, "Kitchen Echo")
    }

    func test_init_fallsBackToDefaultWhenNoStoredName() {
        let mock = MockPeripheralManager()
        let store = MockLocalNameStore()
        store.storedName = nil

        let viewModel = AdvertiseViewModel(peripheralManager: mock, localNameStore: store)

        XCTAssertEqual(viewModel.localName, "BlueScope")
    }

    func test_init_fallsBackToDefaultWhenStoredNameIsBlank() {
        let mock = MockPeripheralManager()
        let store = MockLocalNameStore()
        store.storedName = "   "

        let viewModel = AdvertiseViewModel(peripheralManager: mock, localNameStore: store)

        XCTAssertEqual(viewModel.localName, "BlueScope")
    }

    func test_commitLocalNameChange_savesTrimmedName() {
        let mock = MockPeripheralManager()
        let store = MockLocalNameStore()
        let viewModel = AdvertiseViewModel(peripheralManager: mock, localNameStore: store)
        viewModel.localName = "  Living Room  "

        viewModel.commitLocalNameChange()

        XCTAssertEqual(viewModel.localName, "Living Room")
        XCTAssertEqual(store.storedName, "Living Room")
    }

    func test_commitLocalNameChange_emptyInputFallsBackToDefault() {
        let mock = MockPeripheralManager()
        let store = MockLocalNameStore()
        let viewModel = AdvertiseViewModel(peripheralManager: mock, localNameStore: store)
        viewModel.localName = "   "

        viewModel.commitLocalNameChange()

        XCTAssertEqual(viewModel.localName, "BlueScope")
        XCTAssertEqual(store.storedName, "BlueScope")
    }

    func test_commitLocalNameChange_whileAdvertisingRestartsWithNewName() {
        let mock = MockPeripheralManager()
        let viewModel = AdvertiseViewModel(peripheralManager: mock, localNameStore: MockLocalNameStore())
        viewModel.start()
        viewModel.localName = "New Name"

        viewModel.commitLocalNameChange()

        XCTAssertTrue(mock.didStartAdvertising)
        XCTAssertEqual(mock.advertisedLocalName, "New Name")
    }
}
