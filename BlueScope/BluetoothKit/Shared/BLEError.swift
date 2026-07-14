import Foundation

/// Every failure mode BluetoothKit can produce, named for what actually went
/// wrong rather than passed through as a generic Error. This is what lets a
/// view model show "Connection timed out" instead of "Operation could not be
/// completed. (CBATTErrorDomain error 14.)"
enum BLEError: Error, Equatable {
    case bluetoothUnavailable(BluetoothState)
    case connectionTimeout
    case connectionFailed(String)
    case disconnected(String?)
    case serviceDiscoveryFailed(String)
    case characteristicDiscoveryFailed(String)
    case readFailed(String)
    case writeFailed(String)
    case notSubscribable
    case peripheralNotFound
    case advertisingFailed(String)

    var localizedDescription: String {
        switch self {
        case .bluetoothUnavailable(let state):
            return state.userFacingMessage ?? "Bluetooth is unavailable."
        case .connectionTimeout:
            return "Connection timed out."
        case .connectionFailed(let reason):
            return "Couldn't connect: \(reason)"
        case .disconnected(let reason):
            return reason.map { "Disconnected: \($0)" } ?? "Disconnected."
        case .serviceDiscoveryFailed(let reason):
            return "Couldn't discover services: \(reason)"
        case .characteristicDiscoveryFailed(let reason):
            return "Couldn't discover characteristics: \(reason)"
        case .readFailed(let reason):
            return "Read failed: \(reason)"
        case .writeFailed(let reason):
            return "Write failed: \(reason)"
        case .notSubscribable:
            return "This characteristic doesn't support notifications."
        case .peripheralNotFound:
            return "Device is no longer available."
        case .advertisingFailed(let reason):
            return "Couldn't start advertising: \(reason)"
        }
    }
}
