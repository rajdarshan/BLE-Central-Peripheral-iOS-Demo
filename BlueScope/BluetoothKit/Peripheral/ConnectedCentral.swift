import Foundation

/// A remote central currently subscribed to our advertised characteristic.
/// Entity — same physical central, tracked by id, across its whole session.
struct ConnectedCentral: Identifiable, Equatable {
    let id: UUID
    var isSubscribed: Bool
    var lastActivity: Date
}

/// One line in the live "what just happened" feed on the Connected Centrals
/// screen. Value type — it's a fact that occurred, never mutated after creation.
struct CentralRequestLogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let centralID: UUID
    let message: String
}
