import Foundation
import Combine

@MainActor
final class ConnectedCentralsViewModel: ObservableObject {

    @Published private(set) var connectedCentrals: [ConnectedCentral] = []
    @Published private(set) var requestLog: [CentralRequestLogEntry] = []

    private let peripheralManager: PeripheralManaging

    init(peripheralManager: PeripheralManaging) {
        self.peripheralManager = peripheralManager
        peripheralManager.connectedCentralsPublisher.assign(to: &$connectedCentrals)
        peripheralManager.requestLogPublisher.assign(to: &$requestLog)
    }

    func pushValue(_ text: String) {
        guard let data = text.data(using: .utf8) else { return }
        peripheralManager.pushValue(data)
    }
}
