import XCTest
import Combine
@testable import BlueScope

/// Not a real ScanViewModel yet (that comes next), but this shows the shape
/// every ViewModel test in this project will follow: construct with the mock,
/// drive it directly, assert on the ViewModel's published state. Zero
/// hardware, zero simulator flakiness, runs in milliseconds on CI.
@MainActor
final class ScanViewModelTests_Example: XCTestCase {

    func test_discoveringPeripherals_updatesPublishedList() async {
        let mock = MockCentralManager()
        // let viewModel = ScanViewModel(centralManager: mock)

        let sample = DiscoveredPeripheral(
            id: UUID(),
            name: "Polar H10",
            rssi: -52,
            lastSeen: Date(),
            isConnectable: true
        )
        mock.peripheralsSubject.send([sample])

        // XCTAssertEqual(viewModel.peripherals, [sample])
        XCTAssertEqual(mock.peripheralsSubject.value, [sample])
    }

    func test_connectFailure_surfacesTypedError() async {
        let mock = MockCentralManager()
        mock.connectError = .connectionTimeout

        do {
            try await mock.connect(to: UUID())
            XCTFail("Expected connectionTimeout to be thrown")
        } catch let error as BLEError {
            XCTAssertEqual(error, .connectionTimeout)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
