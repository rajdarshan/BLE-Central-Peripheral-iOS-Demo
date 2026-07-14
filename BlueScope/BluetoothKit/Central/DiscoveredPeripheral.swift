import Foundation

/// A device seen during scanning. This is an entity — same physical device,
/// same identity, across repeated advertisements — so equality is by id only
/// and it's safe to update rssi/lastSeen in place as new adverts arrive.
struct DiscoveredPeripheral: Identifiable, Equatable, Hashable {
    let id: UUID
    var name: String?
    var rssi: Int
    var lastSeen: Date
    var isConnectable: Bool

    static func == (lhs: DiscoveredPeripheral, rhs: DiscoveredPeripheral) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    /// Normalized 0.0–1.0 signal strength, for SF Symbols' `variableValue`
    /// wifi icon (Image(systemName: "wifi", variableValue:)).
    var signalStrengthFraction: Double {
        let clamped = min(max(Double(rssi), -100), -30)
        return (clamped + 100) / 70
    }
}
