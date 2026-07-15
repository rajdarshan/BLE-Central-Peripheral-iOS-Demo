import Foundation
import Combine

@MainActor
final class AdvertiseViewModel: ObservableObject {

    static let defaultLocalName = "BlueScope"

    @Published private(set) var isAdvertising = false
    @Published private(set) var bluetoothState: BluetoothState = .unknown
    @Published private(set) var connectedCentralsCount = 0

    @Published var localName: String

    private let peripheralManager: PeripheralManaging
    private let localNameStore: LocalNamePersisting

    init(
        peripheralManager: PeripheralManaging,
        localNameStore: LocalNamePersisting = UserDefaultsLocalNameStore()
    ) {
        self.peripheralManager = peripheralManager
        self.localNameStore = localNameStore

        let stored = localNameStore.loadLocalName()?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.localName = (stored?.isEmpty == false) ? stored! : Self.defaultLocalName

        peripheralManager.isAdvertisingPublisher.assign(to: &$isAdvertising)
        peripheralManager.statePublisher.assign(to: &$bluetoothState)
        peripheralManager.connectedCentralsPublisher
            .map(\.count)
            .assign(to: &$connectedCentralsCount)
    }

    func start() {
        peripheralManager.startAdvertising(localName: localName)
    }

    func stop() {
        peripheralManager.stopAdvertising()
    }

    func commitLocalNameChange() {
        let trimmed = localName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? Self.defaultLocalName : trimmed
        localName = finalName
        localNameStore.save(localName: finalName)

        guard isAdvertising else { return }
        peripheralManager.stopAdvertising()
        peripheralManager.startAdvertising(localName: finalName)
    }
}
