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

    /// Coarse device categorization for the scan list's icon. Scan-time
    /// advertisement data doesn't reliably expose GATT service UUIDs before
    /// connecting, so this is a best-effort keyword match against the
    /// advertised name rather than a guarantee.
    var deviceKind: DeviceKind {
        guard let name = name?.lowercased() else { return .unknown }
        if DeviceKind.heartRateKeywords.contains(where: { name.contains($0) }) {
            return .heartRate
        }
        if DeviceKind.genericHardwareKeywords.contains(where: { name.contains($0) }) {
            return .genericHardware
        }
        return .unknown
    }
}

enum DeviceKind: Equatable {
    case heartRate
    case genericHardware
    case unknown

    fileprivate static let heartRateKeywords = ["heart", "hrm", "polar", "tickr", "wahoo"]
    fileprivate static let genericHardwareKeywords = [
        "esp32", "esp8266", "arduino", "nrf", "stm32", "raspberry", "pico", "board", "devkit"
    ]

    var systemImage: String {
        switch self {
        case .heartRate: return "waveform.path.ecg"
        case .genericHardware: return "cpu"
        case .unknown: return "questionmark.circle"
        }
    }
}
