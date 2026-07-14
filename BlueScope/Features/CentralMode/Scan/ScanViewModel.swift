import Foundation
import Combine

/// Drives the scan screen: forwards CentralManaging's discovered-peripherals
/// stream into published state, and starts/stops scanning to match the
/// view's lifecycle.
@MainActor
final class ScanViewModel: ObservableObject {

    @Published private(set) var peripherals: [DiscoveredPeripheral] = []

    private let centralManager: CentralManaging

    init(centralManager: CentralManaging) {
        self.centralManager = centralManager
        centralManager.discoveredPeripheralsPublisher.assign(to: &$peripherals)
    }

    func onAppear() {
        centralManager.startScanning()
    }

    func onDisappear() {
        centralManager.stopScanning()
    }

    /// Called when a row is tapped, before the view navigates to Device
    /// Detail — stops scanning since only one peripheral matters from here.
    func didSelect(_ peripheral: DiscoveredPeripheral) {
        centralManager.stopScanning()
    }
}
