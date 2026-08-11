import Foundation

/// Persists which BLE role was last active across launches. Kept behind a
/// protocol so RoleManager doesn't depend on UserDefaults directly and can
/// be unit tested without touching real user defaults.
protocol RolePersisting {
    func loadLastRole() -> AppRole?
    func save(role: AppRole)
}

struct UserDefaultsRolePersisting: RolePersisting {
    private static let key = "role.lastActive"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func loadLastRole() -> AppRole? {
        defaults.string(forKey: Self.key).flatMap(AppRole.init(rawValue:))
    }

    func save(role: AppRole) {
        defaults.set(role.rawValue, forKey: Self.key)
    }
}
