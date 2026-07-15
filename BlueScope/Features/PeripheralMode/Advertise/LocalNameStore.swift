import Foundation

/// Persists the peripheral's advertised local name across launches. Kept
/// behind a protocol so AdvertiseViewModel doesn't depend on UserDefaults
/// directly and can be unit tested without touching real user defaults.
protocol LocalNamePersisting {
    func loadLocalName() -> String?
    func save(localName: String)
}

struct UserDefaultsLocalNameStore: LocalNamePersisting {
    private static let key = "advertise.localName"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadLocalName() -> String? {
        defaults.string(forKey: Self.key)
    }

    func save(localName: String) {
        defaults.set(localName, forKey: Self.key)
    }
}
