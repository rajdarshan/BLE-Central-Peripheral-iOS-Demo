import SwiftUI

struct ScanView: View {
    @StateObject private var viewModel: ScanViewModel

    init(centralManager: CentralManaging) {
        _viewModel = StateObject(wrappedValue: ScanViewModel(centralManager: centralManager))
    }

    var body: some View {
        Group {
            if viewModel.peripherals.isEmpty {
                EmptyStateView(
                    systemImage: "wifi.slash",
                    title: "No devices found",
                    message: "Make sure nearby devices are powered on and advertising."
                )
            } else {
                List(viewModel.peripherals) { peripheral in
                    NavigationLink(value: peripheral.id) {
                        PeripheralRowView(peripheral: peripheral)
                    }
                    .simultaneousGesture(TapGesture().onEnded {
                        viewModel.didSelect(peripheral)
                    })
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Scan")
        .navigationDestination(for: UUID.self) { _ in
            // Stub: Device Detail feature isn't built yet.
            Text("Device Detail")
                .navigationTitle("Device Detail")
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

/// Local, feature-scoped subview — not reused outside the scan list.
private struct PeripheralRowView: View {
    let peripheral: DiscoveredPeripheral

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "wifi", variableValue: peripheral.signalStrengthFraction)
                .font(.system(size: 18))
                .foregroundStyle(Color.accentPrimary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(peripheral.name ?? "Unknown Device")
                    .font(.bodyText)
                    .foregroundStyle(Color.textPrimary)
                Text("\(peripheral.rssi) dBm")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        ScanView(centralManager: CentralManager())
    }
}
