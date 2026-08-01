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
}
