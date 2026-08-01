import CoreBluetooth

/// Our own representation of Bluetooth availability, translated once from
/// CBManagerState right at the CoreBluetooth boundary. Nothing outside this
/// file should ever switch on a raw CBManagerState.
nonisolated enum BluetoothState: Equatable {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn

    init(_ cbState: CBManagerState) {
        switch cbState {
        case .unknown: self = .unknown
        case .resetting: self = .resetting
        case .unsupported: self = .unsupported
        case .unauthorized: self = .unauthorized
        case .poweredOff: self = .poweredOff
        case .poweredOn: self = .poweredOn
        @unknown default: self = .unknown
        }
    }

    var isUsable: Bool { self == .poweredOn }

    /// nil when there's nothing the user needs to be told (i.e. everything's fine).
    var userFacingMessage: String? {
        switch self {
        case .poweredOn: return nil
        case .poweredOff: return "Turn on Bluetooth to continue."
        case .unauthorized: return "BlueScope needs Bluetooth permission. Enable it in Settings."
        case .unsupported: return "This device doesn't support Bluetooth Low Energy."
        case .resetting: return "Bluetooth is resetting. One moment…"
        case .unknown: return "Waiting for Bluetooth to become available…"
        }
    }
}
