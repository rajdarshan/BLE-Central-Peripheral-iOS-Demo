import CoreBluetooth

extension CBUUID {
    /// Best-effort human-readable name for well-known GATT UUIDs.
    /// Falls back to the raw UUID string for vendor-specific ones.
    var friendlyName: String {
        switch self.uuidString {
        // Well-Known GATT Services
        case "1800": return "Generic Access"
        case "180D": return "Heart Rate Service"
        case "1801": return "Generic Attribute"
        case "180A": return "Device Information"
        case "180F": return "Battery Service"
        case "1809": return "Health Thermometer"
        case "1810": return "Blood Pressure"
        case "1822": return "Cycling Speed and Cadence"
        case "1805": return "Current Time Service"
        // Well-Known GATT Characteristics
        case "2A00": return "Device Name"
        case "2A01": return "Appearance"
        case "2A37": return "Heart Rate Measurement"
        case "2A19": return "Battery Level"
        case "2A29": return "Manufacturer Name"
        case "2A24": return "Model Number"
        case "2A1C": return "Temperature Measurement"
        case "FE01": return "Echo Service"
        case "FE02": return "Echo Characteristic"
        default: return self.uuidString
        }
    }
}
