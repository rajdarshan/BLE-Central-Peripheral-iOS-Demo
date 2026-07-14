import CoreBluetooth

extension CBUUID {
    /// Best-effort human-readable name for well-known GATT UUIDs.
    /// Falls back to the raw UUID string for vendor-specific ones.
    var friendlyName: String {
        switch self.uuidString {
        case "180D": return "Heart Rate Service"
        case "2A37": return "Heart Rate Measurement"
        case "180F": return "Battery Service"
        case "2A19": return "Battery Level"
        case "1800": return "Generic Access"
        case "1801": return "Generic Attribute"
        case "FE01": return "Echo Service"
        case "FE02": return "Echo Characteristic"
        default: return self.uuidString
        }
    }
}
