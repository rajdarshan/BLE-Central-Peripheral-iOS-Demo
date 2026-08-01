import CoreBluetooth

/// Our own read/write/notify flags, translated once from CBCharacteristicProperties.
/// Collapses CoreBluetooth's finer-grained cases (write vs writeWithoutResponse,
/// notify vs indicate) into the three that actually matter for the UI.
struct CharacteristicProperties: OptionSet {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }

    static let read = CharacteristicProperties(rawValue: 1 << 0)
    static let write = CharacteristicProperties(rawValue: 1 << 1)
    static let notify = CharacteristicProperties(rawValue: 1 << 2)

    init(_ cbProperties: CBCharacteristicProperties) {
        var props: CharacteristicProperties = []
        if cbProperties.contains(.read) { props.insert(.read) }
        if cbProperties.contains(.write) || cbProperties.contains(.writeWithoutResponse) { props.insert(.write) }
        if cbProperties.contains(.notify) || cbProperties.contains(.indicate) { props.insert(.notify) }
        self = props
    }
}

/// A characteristic within a connected service. Latest value is mutable in
/// place — same characteristic identity, new value over time.
struct DiscoveredCharacteristic: Identifiable, Equatable {
    let id: CBUUID
    let name: String
    let properties: CharacteristicProperties
    var latestValue: CharacteristicValue?

    static func == (lhs: DiscoveredCharacteristic, rhs: DiscoveredCharacteristic) -> Bool {
        lhs.id == rhs.id && lhs.latestValue == rhs.latestValue
    }
}

/// A GATT service on a connected peripheral, containing its characteristics.
/// Containment is expressed directly in the type (service *has* characteristics)
/// rather than reconstructed later by filtering a flat array at the UI layer.
struct DiscoveredService: Identifiable, Equatable {
    let id: CBUUID
    let name: String
    var characteristics: [DiscoveredCharacteristic]

    static func == (lhs: DiscoveredService, rhs: DiscoveredService) -> Bool {
        lhs.id == rhs.id && lhs.characteristics == rhs.characteristics
    }
}
