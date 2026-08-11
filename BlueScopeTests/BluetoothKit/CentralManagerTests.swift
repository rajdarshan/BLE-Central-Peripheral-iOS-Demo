import XCTest
@testable import BlueScope

/// Delegate-callback-driven behavior (didDisconnectPeripheral, willRestoreState)
/// can't be exercised here — CBPeripheral has no public initializer, so
/// there's no way to construct one in a unit test. Those paths are verified
/// manually on-device; see the comments at their call sites in
/// CentralManager.swift.
@MainActor
final class CentralManagerTests: XCTestCase {

    func test_backoffDelay_isExponential() {
        XCTAssertEqual(CentralManager.backoffDelay(forAttempt: 1), .seconds(1))
        XCTAssertEqual(CentralManager.backoffDelay(forAttempt: 2), .seconds(2))
        XCTAssertEqual(CentralManager.backoffDelay(forAttempt: 3), .seconds(4))
        XCTAssertEqual(CentralManager.backoffDelay(forAttempt: 4), .seconds(8))
    }

    func test_connect_toUnknownPeripheral_throwsPeripheralNotFound() async {
        let manager = CentralManager()

        do {
            try await manager.connect(to: UUID())
            XCTFail("Expected connect(to:) to throw for an unregistered peripheral")
        } catch let error as BLEError {
            XCTAssertEqual(error, .peripheralNotFound)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
