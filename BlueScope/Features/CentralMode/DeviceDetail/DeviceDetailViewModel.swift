import Foundation
import Combine

/// Drives the device detail screen: connects to the selected peripheral on
/// appear, forwards CentralManaging's connection-state stream into published
/// state, and disconnects on request.
@MainActor
final class DeviceDetailViewModel: ObservableObject {

    @Published private(set) var connectionState: ConnectionState = .disconnected

    let peripheral: DiscoveredPeripheral

    private let centralManager: CentralManaging

    init(peripheral: DiscoveredPeripheral, centralManager: CentralManaging) {
        self.peripheral = peripheral
        self.centralManager = centralManager
        centralManager.connectionStatePublisher.assign(to: &$connectionState)
    }

    func onAppear() async {
        do {
            try await centralManager.connect(to: peripheral.id)
        } catch let error as BLEError {
            connectionState = .failed(error)
        } catch {
            connectionState = .failed(.connectionFailed(error.localizedDescription))
        }
    }

    func disconnect() async {
        await centralManager.disconnect()
    }
}
