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
        List {
            Section {
                ConnectionStatusBadge(state: viewModel.connectionState)
            }

            if case .connected(let services) = viewModel.connectionState {
                ForEach(services) { service in
                    Section(service.name) {
                        ForEach(service.characteristics) { characteristic in
                            NavigationLink {
                                CharacteristicDetailView(
                                    characteristic: characteristic,
                                    serviceID: service.id,
                                    centralManager: centralManager
                                )
                            } label: {
                                CharacteristicRowView(characteristic: characteristic)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(viewModel.peripheral.name ?? "Unknown Device")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Disconnect") {
                    Task { await viewModel.disconnect() }
                }
            }
        }
        .task {
            await viewModel.onAppear()
        }
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
                    PropertyBadge(label: "R", background: .badgeReadBg, foreground: .badgeReadText)
                }
                if characteristic.properties.contains(.write) {
                    PropertyBadge(label: "W", background: .badgeWriteBg, foreground: .badgeWriteText)
                }
                if characteristic.properties.contains(.notify) {
                    PropertyBadge(label: "N", background: .badgeNotifyBg, foreground: .badgeNotifyText)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct PropertyBadge: View {
    let label: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(label)
            .font(.captionText)
            .foregroundStyle(foreground)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(background, in: Capsule())
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
