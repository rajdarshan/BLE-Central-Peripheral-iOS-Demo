import XCTest
import Combine
import CoreBluetooth
@testable import BlueScope

@MainActor
final class CharacteristicDetailViewModelTests: XCTestCase {

    private let sampleCharacteristic = DiscoveredCharacteristic(
        id: CBUUID(string: "2A19"),
        name: "Battery Level",
        properties: [.read, .notify],
        latestValue: nil
    )
    private let sampleServiceID = CBUUID(string: "180F")

    func test_readOnce_success_updatesLatestValue() async {
        let mock = MockCentralManager()
        let expected = CharacteristicValue(data: Data([0x64]))
        mock.readResult = .success(expected)
        let viewModel = CharacteristicDetailViewModel(
            characteristic: sampleCharacteristic,
            serviceID: sampleServiceID,
            centralManager: mock
        )

        await viewModel.readOnce()

        XCTAssertEqual(viewModel.latestValue, expected)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_readOnce_failure_surfacesErrorMessage() async {
        let mock = MockCentralManager()
        mock.readResult = .failure(.readFailed("timeout"))
        let viewModel = CharacteristicDetailViewModel(
            characteristic: sampleCharacteristic,
            serviceID: sampleServiceID,
            centralManager: mock
        )

        await viewModel.readOnce()

        XCTAssertNil(viewModel.latestValue)
        XCTAssertEqual(viewModel.errorMessage, "Read failed: timeout")
    }

    func test_setNotificationsEnabled_success_updatesFlag() async {
        let mock = MockCentralManager()
        let viewModel = CharacteristicDetailViewModel(
            characteristic: sampleCharacteristic,
            serviceID: sampleServiceID,
            centralManager: mock
        )

        await viewModel.setNotificationsEnabled(true)

        XCTAssertTrue(viewModel.notificationsEnabled)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_setNotificationsEnabled_failure_surfacesErrorAndLeavesFlagUnchanged() async {
        let mock = MockCentralManager()
        mock.notifyError = .notSubscribable
        let viewModel = CharacteristicDetailViewModel(
            characteristic: sampleCharacteristic,
            serviceID: sampleServiceID,
            centralManager: mock
        )

        await viewModel.setNotificationsEnabled(true)

        XCTAssertFalse(viewModel.notificationsEnabled)
        XCTAssertEqual(viewModel.errorMessage, "This characteristic doesn't support notifications.")
    }
}
