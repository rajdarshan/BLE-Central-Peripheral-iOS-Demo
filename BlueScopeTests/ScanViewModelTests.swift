import XCTest
import Combine
@testable import BlueScope

@MainActor
final class ScanViewModelTests: XCTestCase {

    func test_discoveringPeripherals_updatesPublishedList() async {
        let mock = MockCentralManager()
        let viewModel = ScanViewModel(centralManager: mock)

        let sample = DiscoveredPeripheral(
            id: UUID(),
            name: "Polar H10",
            rssi: -52,
            lastSeen: Date(),
            isConnectable: true
        )
        mock.peripheralsSubject.send([sample])

        XCTAssertEqual(viewModel.peripherals, [sample])
    }

    func test_onAppear_startsScanning() {
        let mock = MockCentralManager()
        let viewModel = ScanViewModel(centralManager: mock)

        viewModel.onAppear()

        XCTAssertTrue(mock.didStartScanning)
    }

    func test_onDisappear_stopsScanning() {
        let mock = MockCentralManager()
        let viewModel = ScanViewModel(centralManager: mock)

        viewModel.onAppear()
        viewModel.onDisappear()

        XCTAssertTrue(mock.didStopScanning)
        XCTAssertFalse(mock.didStartScanning)
    }
}
