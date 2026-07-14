import Foundation
import Combine

/// Whether the Scan screen is actively scanning or has stopped (by timeout,
/// manual stop, or navigating into a device). Modeled as an enum, not a
/// Bool, to match the rest of the codebase's state-machine convention.
enum ScanState: Equatable {
    case scanning
    case completed
}

/// Drives the scan screen: forwards CentralManaging's discovered-peripherals
/// stream into published state, and starts/stops scanning to match the
/// view's lifecycle. Also bounds each scan to `scanTimeout`, auto-stopping
/// it the way a user tapping "Stop" would.
@MainActor
final class ScanViewModel: ObservableObject {

    @Published private(set) var peripherals: [DiscoveredPeripheral] = []
    @Published private(set) var scanState: ScanState = .scanning

    private let centralManager: CentralManaging
    private let scanTimeout: Duration
    private var timeoutTask: Task<Void, Never>?

    init(centralManager: CentralManaging, scanTimeout: Duration = .seconds(60)) {
        self.centralManager = centralManager
        self.scanTimeout = scanTimeout
        centralManager.discoveredPeripheralsPublisher.assign(to: &$peripherals)
    }

    func onAppear() {
        startScan()
    }

    func onDisappear() {
        stopScan()
    }

    /// Called by the toolbar button to manually stop an in-progress scan
    /// or restart one that finished (timed out or was stopped).
    func toggleScan() {
        switch scanState {
        case .scanning: stopScan()
        case .completed: startScan()
        }
    }

    /// Called when a row is tapped, before the view navigates to Device
    /// Detail — stops scanning since only one peripheral matters from here.
    func didSelect(_ peripheral: DiscoveredPeripheral) {
        stopScan()
    }

    private func startScan() {
        centralManager.startScanning()
        scanState = .scanning
        timeoutTask?.cancel()
        timeoutTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.scanTimeout)
            guard !Task.isCancelled else { return }
            self.stopScan()
        }
    }

    private func stopScan() {
        timeoutTask?.cancel()
        timeoutTask = nil
        centralManager.stopScanning()
        scanState = .completed
    }
}
