import Foundation
import Combine

/// Owns the single BLE role the app is currently acting as, and the one
/// CentralManaging + one PeripheralManaging instance that back it. Nothing
/// else should construct CentralManager()/PeripheralManager() directly —
/// go through here so teardown between roles always happens.
@MainActor
final class RoleManager: ObservableObject {

    @Published private(set) var activeRole: AppRole?
    @Published private(set) var isSwitchingRole = false

    private let centralManager: CentralManaging
    let peripheralManager: PeripheralManaging

    init(
        centralManager: CentralManaging? = nil,
        peripheralManager: PeripheralManaging? = nil
    ) {
        // Default arguments are evaluated in a nonisolated context even
        // though init() itself is MainActor, so the real managers are
        // constructed here in the (MainActor) body instead of inline above.
        self.centralManager = centralManager ?? CentralManager()
        self.peripheralManager = peripheralManager ?? PeripheralManager()
    }

    /// Tears down whichever manager is currently active, then activates `role`.
    /// Checks the target role's Bluetooth state first — if it isn't usable,
    /// throws before touching anything, so a failed switch leaves the
    /// previously active role (and its manager) untouched.
    func activate(_ role: AppRole) async throws {
        guard role != activeRole else { return }

        isSwitchingRole = true
        defer { isSwitchingRole = false }

        let state: BluetoothState
        switch role {
        case .central:
            state = await currentState(of: centralManager.statePublisher)
        case .peripheral:
            state = await currentState(of: peripheralManager.statePublisher)
        }
        guard state.isUsable else {
            throw BLEError.bluetoothUnavailable(state)
        }

        switch activeRole {
        case .central:
            centralManager.tearDown()
        case .peripheral:
            peripheralManager.tearDown()
        case nil:
            break
        }

        activeRole = role
    }

    private func currentState(of publisher: AnyPublisher<BluetoothState, Never>) async -> BluetoothState {
        var iterator = publisher.values.makeAsyncIterator()
        return await iterator.next() ?? .unknown
    }
}
