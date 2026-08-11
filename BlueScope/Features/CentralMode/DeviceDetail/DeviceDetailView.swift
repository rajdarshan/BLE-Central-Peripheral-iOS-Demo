import SwiftUI
import CoreBluetooth

struct DeviceDetailView: View {
    @StateObject private var viewModel: DeviceDetailViewModel
    private let centralManager: CentralManaging

    init(peripheral: DiscoveredPeripheral, centralManager: CentralManaging) {
        _viewModel = StateObject(wrappedValue: DeviceDetailViewModel(peripheral: peripheral, centralManager: centralManager))
        self.centralManager = centralManager
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    ConnectionStatusBadge(state: viewModel.connectionState)
                    Spacer()
                }

                if case .connected(let services) = viewModel.connectionState {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Services")
                            .font(.sectionHeader)
                            .foregroundStyle(Color.textSecondary)
                            .textCase(.uppercase)

                        VStack(spacing: 12) {
                            ForEach(services) { service in
                                ServiceCardView(service: service, centralManager: centralManager)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.surfaceSecondary)
        .navigationTitle(viewModel.peripheral.name ?? "Unknown Device")
        .safeAreaInset(edge: .bottom) {
            switch viewModel.connectionState {
            case .connected:
                OutlinedButton(title: "Disconnect", color: .statusError) {
                    Task { await viewModel.disconnect() }
                }
                .padding(16)
                .background(Color.surfaceSecondary)
            case .disconnected, .failed, .reconnectFailed:
                OutlinedButton(title: "Connect", color: .accentPrimary) {
                    Task { await viewModel.connect() }
                }
                .padding(16)
                .background(Color.surfaceSecondary)
            case .connecting, .discoveringServices, .reconnecting:
                EmptyView()
            }
        }
        .task {
            await viewModel.onAppear()
        }
    }
}

/// Local, feature-scoped subview — a card for one GATT service showing its
/// friendly name, UUID, and characteristic rows.
private struct ServiceCardView: View {
    let service: DiscoveredService
    let centralManager: CentralManaging

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(service.id.friendlyName)
                    .font(.bodyText.bold())
                    .foregroundStyle(Color.textPrimary)
                Text("0x\(service.id.uuidString)")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            }

            Divider()

            VStack(spacing: 12) {
                ForEach(Array(service.characteristics.enumerated()), id: \.element.id) { index, characteristic in
                    NavigationLink {
                        CharacteristicDetailView(
                            characteristic: characteristic,
                            serviceID: service.id,
                            centralManager: centralManager
                        )
                    } label: {
                        CharacteristicRowView(characteristic: characteristic)
                    }
                    .buttonStyle(.plain)

                    if index < service.characteristics.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding(12)
        .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderDefault, lineWidth: 1))
    }
}

/// Local, feature-scoped subview — not reused outside the device detail list.
private struct CharacteristicRowView: View {
    let characteristic: DiscoveredCharacteristic

    var body: some View {
        HStack {
            Text(characteristic.name)
                .font(.bodyText)
                .foregroundStyle(Color.textPrimary)

            Spacer()

            HStack(spacing: 6) {
                if characteristic.properties.contains(.read) {
                    PropertyBadge(label: "read", background: .badgeReadBg, foreground: .badgeReadText)
                }
                if characteristic.properties.contains(.write) {
                    PropertyBadge(label: "write", background: .badgeWriteBg, foreground: .badgeWriteText)
                }
                if characteristic.properties.contains(.notify) {
                    PropertyBadge(label: "notify", background: .badgeNotifyBg, foreground: .badgeNotifyText)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DeviceDetailView(
            peripheral: DiscoveredPeripheral(
                id: UUID(),
                name: "Polar H10",
                rssi: -52,
                lastSeen: Date(),
                isConnectable: true
            ),
            centralManager: CentralManager()
        )
    }
}
