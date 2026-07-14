import Foundation

/// A value read/received from a characteristic at a point in time. This is a
/// value type (no identity of its own) — it just describes "here's what the
/// bytes meant when we last heard from this characteristic."
struct CharacteristicValue: Equatable {
    let data: Data
    let receivedAt: Date

    init(data: Data, receivedAt: Date = Date()) {
        self.data = data
        self.receivedAt = receivedAt
    }

    var hexString: String {
        data.map { String(format: "%02X", $0) }.joined(separator: " ")
    }

    var asciiString: String {
        String(data: data, encoding: .ascii) ?? "—"
    }

    var decimalString: String {
        data.map { String($0) }.joined(separator: " ")
    }

    func formatted(as format: ValueFormat) -> String {
        switch format {
        case .hex: return hexString
        case .ascii: return asciiString
        case .decimal: return decimalString
        }
    }
}

enum ValueFormat: String, CaseIterable, Identifiable, Hashable {
    case decimal, hex, ascii
    var id: String { rawValue }

    var label: String {
        switch self {
        case .decimal: return "Decimal"
        case .hex: return "Hex"
        case .ascii: return "ASCII"
        }
    }
}
