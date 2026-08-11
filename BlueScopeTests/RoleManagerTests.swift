import XCTest
import Combine
@testable import BlueScope

@MainActor
final class RoleManagerTests: XCTestCase {

    func test_activate_tearsDownPreviouslyActiveManager() async throws {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral)

        try await roleManager.activate(.central)
        XCTAssertEqual(roleManager.activeRole, .central)
        XCTAssertFalse(central.didTearDown)

        try await roleManager.activate(.peripheral)
        XCTAssertEqual(roleManager.activeRole, .peripheral)
        XCTAssertTrue(central.didTearDown)
        XCTAssertFalse(peripheral.didTearDown)
    }

    func test_failedActivation_leavesRoleUnchanged() async {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral)

        try? await roleManager.activate(.central)
        XCTAssertEqual(roleManager.activeRole, .central)

        peripheral.stateSubject.send(.poweredOff)

        do {
            try await roleManager.activate(.peripheral)
            XCTFail("Expected activation to fail when Bluetooth is unavailable")
        } catch let error as BLEError {
            XCTAssertEqual(error, .bluetoothUnavailable(.poweredOff))
        } catch {
            XCTFail("Wrong error type: \(error)")
        }

        XCTAssertEqual(roleManager.activeRole, .central)
        XCTAssertFalse(central.didTearDown)
    }

    func test_isSwitchingRole_trueOnlyDuringSwitch() async throws {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral)

        var observed: [Bool] = []
        let cancellable = roleManager.$isSwitchingRole.sink { observed.append($0) }

        try await roleManager.activate(.central)

        cancellable.cancel()
        XCTAssertEqual(observed, [false, true, false])
    }

    func test_activate_persistsRole() async throws {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        let rolePersisting = MockRolePersisting()
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral, rolePersisting: rolePersisting)

        try await roleManager.activate(.central)

        XCTAssertEqual(rolePersisting.savedRoles, [.central])
    }

    func test_restorePersistedRoleIfNeeded_activatesSavedRole() async {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        let rolePersisting = MockRolePersisting()
        rolePersisting.stubbedLastRole = .central
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral, rolePersisting: rolePersisting)

        let restored = await roleManager.restorePersistedRoleIfNeeded()

        XCTAssertEqual(restored, .central)
        XCTAssertEqual(roleManager.activeRole, .central)
    }

    func test_restorePersistedRoleIfNeeded_returnsNilWhenNothingSaved() async {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        let rolePersisting = MockRolePersisting()
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral, rolePersisting: rolePersisting)

        let restored = await roleManager.restorePersistedRoleIfNeeded()

        XCTAssertNil(restored)
        XCTAssertNil(roleManager.activeRole)
    }

    func test_restorePersistedRoleIfNeeded_returnsNilWhenRoleAlreadyActive() async throws {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        let rolePersisting = MockRolePersisting()
        rolePersisting.stubbedLastRole = .peripheral
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral, rolePersisting: rolePersisting)
        try await roleManager.activate(.central)

        let restored = await roleManager.restorePersistedRoleIfNeeded()

        XCTAssertNil(restored)
        XCTAssertEqual(roleManager.activeRole, .central)
    }

    func test_restorePersistedRoleIfNeeded_returnsNilWhenBluetoothUnusable() async {
        let central = MockCentralManager()
        let peripheral = MockPeripheralManager()
        central.stateSubject.send(.poweredOff)
        let rolePersisting = MockRolePersisting()
        rolePersisting.stubbedLastRole = .central
        let roleManager = RoleManager(centralManager: central, peripheralManager: peripheral, rolePersisting: rolePersisting)

        let restored = await roleManager.restorePersistedRoleIfNeeded()

        XCTAssertNil(restored)
        XCTAssertNil(roleManager.activeRole)
    }
}
