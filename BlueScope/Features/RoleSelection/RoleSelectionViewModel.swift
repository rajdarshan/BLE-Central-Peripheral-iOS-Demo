import Foundation
import Combine

/// Thin wrapper around RoleManager for the role-selection screen. Forwards
/// RoleManager's published state as-is and translates a thrown activation
/// error into a user-facing message instead of letting it propagate.
@MainActor
final class RoleSelectionViewModel: ObservableObject {

    @Published private(set) var selectedRole: AppRole?
    @Published private(set) var isSwitchingRole = false
    @Published var errorMessage: String?

    private let roleManager: RoleManager

    init(roleManager: RoleManager) {
        self.roleManager = roleManager
        roleManager.$activeRole.assign(to: &$selectedRole)
        roleManager.$isSwitchingRole.assign(to: &$isSwitchingRole)
    }

    /// Activates `role` via RoleManager. Returns whether activation
    /// succeeded so the view can decide whether to navigate forward.
    @discardableResult
    func selectRole(_ role: AppRole) async -> Bool {
        do {
            try await roleManager.activate(role)
            errorMessage = nil
            return true
        } catch let error as BLEError {
            errorMessage = error.localizedDescription
            return false
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
