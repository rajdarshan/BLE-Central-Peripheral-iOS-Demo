import XCTest
import Combine
@testable import BlueScope

@MainActor
final class DeviceDetailViewModelTests: XCTestCase {

    private let samplePeripheral = DiscoveredPeripheral(
        id: UUID(),
        name: "Polar H10",
        rssi: -52,
        lastSeen: Date(),
        isConnectable: true
    )

    func test_onAppear_connectsWithCorrectPeripheralID() async {
        let mock = MockCentralManager()
        let viewModel = DeviceDetailViewModel(peripheral: samplePeripheral, centralManager: mock)

        await viewModel.onAppear()

        XCTAssertEqual(mock.connectedPeripheralID, samplePeripheral.id)
    }

    func test_connectFailure_surfacesFailedState() async {
        let mock = MockCentralManager()
        mock.connectError = .connectionTimeout
        let viewModel = DeviceDetailViewModel(peripheral: samplePeripheral, centralManager: mock)

        await viewModel.onAppear()

        guard case .failed(let error) = viewModel.connectionState else {
            XCTFail("Expected .failed state, got \(viewModel.connectionState)")
            return
        }
        XCTAssertEqual(error, .connectionTimeout)
        XCTAssertEqual(error.localizedDescription, "Connection timed out.")
    }

    func test_disconnect_callsManagerDisconnect() async {
        let mock = MockCentralManager()
        let viewModel = DeviceDetailViewModel(peripheral: samplePeripheral, centralManager: mock)

        await viewModel.onAppear()
        XCTAssertEqual(mock.connectedPeripheralID, samplePeripheral.id)

        await viewModel.disconnect()

        XCTAssertNil(mock.connectedPeripheralID)
        XCTAssertEqual(viewModel.connectionState, .disconnected)
    }

    func test_unexpectedDisconnect_surfacesReconnectingThenReconnectFailed() async {
        let mock = MockCentralManager()
        let viewModel = DeviceDetailViewModel(peripheral: samplePeripheral, centralManager: mock)
        await viewModel.onAppear()

        var observed: [ConnectionState] = []
        let cancellable = mock.connectionStatePublisher.dropFirst().sink { observed.append($0) }

        mock.simulateUnexpectedDisconnect(maxAttempts: 4)
        cancellable.cancel()

        XCTAssertEqual(observed, [.reconnecting(attempt: 1, maxAttempts: 4), .reconnectFailed(.disconnected(nil))])
        XCTAssertEqual(viewModel.connectionState, .reconnectFailed(.disconnected(nil)))
    }

    func test_deliberateDisconnect_doesNotSurfaceReconnecting() async {
        let mock = MockCentralManager()
        let viewModel = DeviceDetailViewModel(peripheral: samplePeripheral, centralManager: mock)
        await viewModel.onAppear()

        mock.simulateDeliberateDisconnect()

        XCTAssertEqual(viewModel.connectionState, .disconnected)
    }
}
