import XCTest
import Combine
@testable import BlueScope

@MainActor
final class RoleSelectionViewModelTests: XCTestCase {

    func test_selectRole_callsRoleManagerActivateWithRightRole() async {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral)
        let viewModel = RoleSelectionViewModel(roleManager: roleManager)

        let succeeded = await viewModel.selectRole(.central)

        XCTAssertTrue(succeeded)
        XCTAssertEqual(roleManager.activeRole, .central)
        XCTAssertEqual(viewModel.selectedRole, .central)
    }

    func test_selectRole_thrownError_surfacedViaErrorMessage() async {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        peripheral.stateSubject.send(.poweredOff)
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral)
        let viewModel = RoleSelectionViewModel(roleManager: roleManager)

        let succeeded = await viewModel.selectRole(.peripheral)

        XCTAssertFalse(succeeded)
        XCTAssertEqual(viewModel.errorMessage, BLEError.bluetoothUnavailable(.poweredOff).localizedDescription)
        XCTAssertNil(viewModel.selectedRole)
    }

    func test_restoreIfNeeded_forwardsToRoleManager() async {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        let rolePersisting = MockRolePersisting()
        rolePersisting.stubbedLastRole = .central
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral, rolePersisting: rolePersisting)
        let viewModel = RoleSelectionViewModel(roleManager: roleManager)

        let restored = await viewModel.restoreIfNeeded()

        XCTAssertEqual(restored, .central)
        XCTAssertEqual(viewModel.selectedRole, .central)
    }
}
