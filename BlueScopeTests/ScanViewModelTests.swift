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

    func test_onAppear_startsInScanningState() {
        let mock = MockCentralManager()
        let viewModel = ScanViewModel(centralManager: mock)

        viewModel.onAppear()

        XCTAssertEqual(viewModel.scanState, .scanning)
    }

    func test_toggleScan_whileScanning_stopsAndMarksCompleted() {
        let mock = MockCentralManager()
        let viewModel = ScanViewModel(centralManager: mock)

        viewModel.onAppear()
        viewModel.toggleScan()

        XCTAssertEqual(viewModel.scanState, .completed)
        XCTAssertTrue(mock.didStopScanning)
    }

    func test_toggleScan_whileCompleted_restartsScanning() {
        let mock = MockCentralManager()
        let viewModel = ScanViewModel(centralManager: mock)

        viewModel.onAppear()
        viewModel.toggleScan()
        viewModel.toggleScan()

        XCTAssertEqual(viewModel.scanState, .scanning)
        XCTAssertTrue(mock.didStartScanning)
    }

    func test_didSelect_stopsScanAndMarksCompleted() {
        let mock = MockCentralManager()
        let viewModel = ScanViewModel(centralManager: mock)
        let sample = DiscoveredPeripheral(
            id: UUID(),
            name: "Polar H10",
            rssi: -52,
            lastSeen: Date(),
            isConnectable: true
        )

        viewModel.onAppear()
        viewModel.didSelect(sample)

        XCTAssertEqual(viewModel.scanState, .completed)
        XCTAssertTrue(mock.didStopScanning)
    }

    func test_scanTimeout_autoStopsAfterDuration() async {
        let mock = MockCentralManager()
        let viewModel = ScanViewModel(centralManager: mock, scanTimeout: .milliseconds(50))

        viewModel.onAppear()
        try? await Task.sleep(for: .milliseconds(200))

        XCTAssertEqual(viewModel.scanState, .completed)
        XCTAssertTrue(mock.didStopScanning)
    }
}
