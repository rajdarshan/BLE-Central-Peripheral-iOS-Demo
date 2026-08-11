/// Which BLE role the app is currently acting as. Exactly one is active at
/// a time — RoleManager owns the switch between them.
enum AppRole: String, Hashable {
    case central
    case peripheral

    var title: String {
        switch self {
        case .central: return "Scan for Devices"
        case .peripheral: return "Advertise as Device"
        }
    }

    var subtitle: String {
        switch self {
        case .central: return "Discover and connect to nearby BLE peripherals"
        case .peripheral: return "Broadcast this device as a BLE peripheral"
        }
    }

    var sfSymbolName: String {
        switch self {
        case .central: return "magnifyingglass"
        case .peripheral: return "dot.radiowaves.left.and.right"
        }
    }
}
