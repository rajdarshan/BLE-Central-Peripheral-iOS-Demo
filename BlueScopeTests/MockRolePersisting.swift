import Foundation
@testable import BlueScope

final class MockRolePersisting: RolePersisting {
    var stubbedLastRole: AppRole?
    private(set) var savedRoles: [AppRole] = []

    func loadLastRole() -> AppRole? {
        stubbedLastRole
    }

    func save(role: AppRole) {
        stubbedLastRole = role
        savedRoles.append(role)
    }
}
