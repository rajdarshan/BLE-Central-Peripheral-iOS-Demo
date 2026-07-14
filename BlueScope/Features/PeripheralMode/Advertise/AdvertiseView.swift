import SwiftUI

struct AdvertiseView: View {
    @StateObject private var viewModel: AdvertiseViewModel

    init(peripheralManager: PeripheralManaging) {
        _viewModel = StateObject(wrappedValue: AdvertiseViewModel(peripheralManager: peripheralManager))
    }

    var body: some View {
        List {
            Section {
                AdvertisingStatusCard(
                    isAdvertising: viewModel.isAdvertising,
                    bluetoothState: viewModel.bluetoothState
                )
            }

            Section("Local Name") {
                Text(viewModel.localName)
                    .font(.monospaceValue)
                    .foregroundStyle(Color.textPrimary)
            }

            Section("Echo Service") {
                HStack {
                    Text("Echo Characteristic")
                        .font(.bodyText)
                        .foregroundStyle(Color.textPrimary)

                    Spacer()

                    HStack(spacing: 6) {
                        PropertyBadge(label: "R", background: .badgeReadBg, foreground: .badgeReadText)
                        PropertyBadge(label: "W", background: .badgeWriteBg, foreground: .badgeWriteText)
                        PropertyBadge(label: "N", background: .badgeNotifyBg, foreground: .badgeNotifyText)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                NavigationLink {
                    ConnectedCentralsView()
                } label: {
                    Text("Connected Centrals")
                        .font(.bodyText)
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Advertise")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Stop") {
                    viewModel.stop()
                }
            }
        }
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }
}

/// Local, feature-scoped subview — not reused outside Advertise. Renders
/// isAdvertising + bluetoothState as a single status row; intentionally not
/// ConnectionStatusBadge, which is typed to ConnectionState, not a Bool.
private struct AdvertisingStatusCard: View {
    let isAdvertising: Bool
    let bluetoothState: BluetoothState

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .foregroundStyle(color)
            Text(label)
                .font(.bodyText)
                .foregroundStyle(color)
        }
    }

    private var systemImage: String {
        guard bluetoothState.isUsable else { return "exclamationmark.triangle.fill" }
        return isAdvertising ? "dot.radiowaves.left.and.right" : "pause.circle"
    }

    private var color: Color {
        guard bluetoothState.isUsable else { return .statusError }
        return isAdvertising ? .statusConnected : .statusWarning
    }

    private var label: String {
        if let message = bluetoothState.userFacingMessage { return message }
        return isAdvertising ? "Advertising" : "Not advertising"
    }
}

#Preview {
    NavigationStack {
        AdvertiseView(peripheralManager: PeripheralManager())
    }
}
