import Foundation
import Combine

@MainActor
final class AdvertiseViewModel: ObservableObject {

    @Published private(set) var isAdvertising = false
    @Published private(set) var bluetoothState: BluetoothState = .unknown

    let localName = "BlueScope"

    private let peripheralManager: PeripheralManaging

    init(peripheralManager: PeripheralManaging) {
        self.peripheralManager = peripheralManager
        peripheralManager.isAdvertisingPublisher.assign(to: &$isAdvertising)
        peripheralManager.statePublisher.assign(to: &$bluetoothState)
    }

    func start() {
        peripheralManager.startAdvertising(localName: localName)
    }

    func stop() {
        peripheralManager.stopAdvertising()
    }
}
