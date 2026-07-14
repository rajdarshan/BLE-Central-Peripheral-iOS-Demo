import Foundation
import Combine
import CoreBluetooth

/// Drives the characteristic detail screen: reads on demand, tracks the
/// notification subscription, and keeps `latestValue` current both from
/// explicit reads and from live notify-driven pushes (which arrive as a
/// full connection-state snapshot, same as CentralManager's other updates).
@MainActor
final class CharacteristicDetailViewModel: ObservableObject {

    @Published private(set) var latestValue: CharacteristicValue?
    @Published var selectedFormat: ValueFormat = .hex
    @Published private(set) var notificationsEnabled = false
    @Published private(set) var errorMessage: String?

    let characteristic: DiscoveredCharacteristic
    let serviceID: CBUUID

    private let centralManager: CentralManaging

    private var characteristicIDString: String { characteristic.id.uuidString }

    init(characteristic: DiscoveredCharacteristic, serviceID: CBUUID, centralManager: CentralManaging) {
        self.characteristic = characteristic
        self.serviceID = serviceID
        self.centralManager = centralManager
        self.latestValue = characteristic.latestValue

        centralManager.connectionStatePublisher
            .compactMap { state -> DiscoveredCharacteristic? in
                guard case .connected(let services) = state,
                      let service = services.first(where: { $0.id == serviceID }) else {
                    return nil
                }
                return service.characteristics.first(where: { $0.id == characteristic.id })
            }
            .map { $0.latestValue }
            .assign(to: &$latestValue)
    }

    func readOnce() async {
        do {
            latestValue = try await centralManager.readValue(for: characteristicIDString)
            errorMessage = nil
        } catch let error as BLEError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setNotificationsEnabled(_ enabled: Bool) async {
        do {
            try await centralManager.setNotifications(enabled, for: characteristicIDString)
            notificationsEnabled = enabled
            errorMessage = nil
        } catch let error as BLEError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func write(_ text: String) async {
        guard let data = text.data(using: .utf8) else { return }
        do {
            try await centralManager.writeValue(data, for: characteristicIDString)
            errorMessage = nil
        } catch let error as BLEError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
