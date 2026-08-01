import CoreBluetooth

/// Defines the mock "Echo Service" BlueScope advertises in peripheral mode.
/// Centralizing the UUIDs here means the advertiser and the request-handling
/// delegate can never drift out of sync with each other — there's exactly
/// one place that says what this peripheral's GATT shape is.
enum MockGATTService {
    static let serviceUUID = CBUUID(string: "12345678-1234-5678-1234-56789ABCDEF0")
    static let echoCharacteristicUUID = CBUUID(string: "12345678-1234-5678-1234-56789ABCDEF1")

    static func makeCBService() -> CBMutableService {
        let characteristic = CBMutableCharacteristic(
            type: echoCharacteristicUUID,
            properties: [.read, .write, .notify],
            value: nil,
            permissions: [.readable, .writeable]
        )
        let service = CBMutableService(type: serviceUUID, primary: true)
        service.characteristics = [characteristic]
        return service
    }
}
