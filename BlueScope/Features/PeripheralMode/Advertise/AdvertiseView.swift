import SwiftUI

struct AdvertiseView: View {
    @StateObject private var viewModel: AdvertiseViewModel
    private let peripheralManager: PeripheralManaging

    init(peripheralManager: PeripheralManaging) {
        _viewModel = StateObject(wrappedValue: AdvertiseViewModel(peripheralManager: peripheralManager))
        self.peripheralManager = peripheralManager
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                NavigationLink {
                    ConnectedCentralsView(peripheralManager: peripheralManager)
                } label: {
                    AdvertisingStatusCard(
                        isAdvertising: viewModel.isAdvertising,
                        bluetoothState: viewModel.bluetoothState,
                        connectedCentralsCount: viewModel.connectedCentralsCount
                    )
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Local Name")
                        .font(.sectionHeader)
                        .foregroundStyle(Color.textSecondary)
                        .textCase(.uppercase)

                    TextField("Local Name", text: $viewModel.localName)
                        .font(.bodyText)
                        .foregroundStyle(Color.textPrimary)
                        .submitLabel(.done)
                        .onSubmit { viewModel.commitLocalNameChange() }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                        .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderDefault, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Service")
                        .font(.sectionHeader)
                        .foregroundStyle(Color.textSecondary)
                        .textCase(.uppercase)

                    EchoServiceCardView()
                }
            }
            .padding(16)
        }
        .background(Color.surfaceSecondary)
        .navigationTitle("Advertise")
        .navigationSubtitle("Broadcasting as a mock echo peripheral")
        .safeAreaInset(edge: .bottom) {
            Group {
                if viewModel.isAdvertising {
                    OutlinedButton(title: "Stop advertising", color: .statusError) {
                        viewModel.stop()
                    }
                } else {
                    OutlinedButton(title: "Start advertising", color: .accentPrimary) {
                        viewModel.start()
                    }
                }
            }
            .padding(16)
            .background(Color.surfaceSecondary)
        }
    }
}

/// Local, feature-scoped subview — not reused outside Advertise. Renders
/// isAdvertising + bluetoothState + connectedCentralsCount as a centered
/// status card; intentionally not ConnectionStatusBadge, which is typed to
/// ConnectionState, not a Bool.
private struct AdvertisingStatusCard: View {
    let isAdvertising: Bool
    let bluetoothState: BluetoothState
    let connectedCentralsCount: Int

    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: 64, height: 64)
                .overlay(
                    Image(systemName: systemImage)
                        .font(.system(size: 22))
                        .foregroundStyle(color)
                )

            Text(title)
                .font(.bodyText.bold())
                .foregroundStyle(Color.textPrimary)

            Text(caption)
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderDefault, lineWidth: 1))
    }

    private var systemImage: String {
        guard bluetoothState.isUsable else { return "exclamationmark.triangle.fill" }
        return isAdvertising ? "dot.radiowaves.left.and.right" : "pause.circle"
    }

    private var color: Color {
        guard bluetoothState.isUsable else { return .statusError }
        return isAdvertising ? .accentPrimary : .statusWarning
    }

    private var title: String {
        guard bluetoothState.isUsable else { return "Bluetooth Unavailable" }
        return isAdvertising ? "Advertising" : "Not Advertising"
    }

    private var caption: String {
        guard bluetoothState.isUsable else {
            return bluetoothState.userFacingMessage ?? ""
        }
        guard isAdvertising else { return "Tap Start to begin advertising" }
        return "\(connectedCentralsCount) centrals nearby"
    }
}

/// Local, feature-scoped subview — a card for the mock Echo Service showing
/// its friendly name, short UUID, and supported capability badges. Values
/// are hardcoded here to match the rest of AdvertiseView, rather than
/// reaching into BluetoothKit's MockGATTService for display strings.
private struct EchoServiceCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Echo Service")
                    .font(.bodyText.bold())
                    .foregroundStyle(Color.textPrimary)
                Text("FE01")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            }

            HStack(spacing: 6) {
                PropertyBadge(label: "read", background: .badgeReadBg, foreground: .badgeReadText)
                PropertyBadge(label: "write", background: .badgeWriteBg, foreground: .badgeWriteText)
                PropertyBadge(label: "notify", background: .badgeNotifyBg, foreground: .badgeNotifyText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderDefault, lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        AdvertiseView(peripheralManager: PeripheralManager())
    }
}
