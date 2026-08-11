/// The full lifecycle of a central's connection to one peripheral, modeled
/// as a single enum rather than a cluster of booleans. This makes states
/// like "connected but services is nil" or "disconnected but still showing
/// a spinner" impossible to represent, let alone accidentally produce.
enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case discoveringServices
    case connected(services: [DiscoveredService])
    case failed(BLEError)
    case reconnecting(attempt: Int, maxAttempts: Int)
    case reconnectFailed(BLEError)

    static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
             (.connecting, .connecting),
             (.discoveringServices, .discoveringServices):
            return true
        case (.connected(let lh), .connected(let rh)):
            return lh == rh
        case (.failed(let lh), .failed(let rh)):
            return lh == rh
        case (.reconnecting(let lAttempt, let lMax), .reconnecting(let rAttempt, let rMax)):
            return lAttempt == rAttempt && lMax == rMax
        case (.reconnectFailed(let lh), .reconnectFailed(let rh)):
            return lh == rh
        default:
            return false
        }
    }
}
