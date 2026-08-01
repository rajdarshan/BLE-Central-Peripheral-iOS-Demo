import XCTest
import Combine
@testable import BlueScope

@MainActor
final class ConnectedCentralsViewModelTests: XCTestCase {

    func test_pushValue_encodesTextAndForwardsToManager() {
        let mock = MockPeripheralManager()
        let viewModel = ConnectedCentralsViewModel(peripheralManager: mock)

        viewModel.pushValue("hello")

        XCTAssertEqual(mock.pushedValues, [Data("hello".utf8)])
    }

    func test_connectedCentrals_reflectsManagerPublisher() {
        let mock = MockPeripheralManager()
        let viewModel = ConnectedCentralsViewModel(peripheralManager: mock)

        let central = ConnectedCentral(id: UUID(), isSubscribed: true, lastActivity: Date())
        mock.centralsSubject.send([central])

        XCTAssertEqual(viewModel.connectedCentrals, [central])
    }

    func test_requestLog_reflectsManagerPublisher() {
        let mock = MockPeripheralManager()
        let viewModel = ConnectedCentralsViewModel(peripheralManager: mock)

        let entry = CentralRequestLogEntry(timestamp: Date(), centralID: UUID(), message: "Read request")
        mock.logSubject.send([entry])

        XCTAssertEqual(viewModel.requestLog, [entry])
    }
}
