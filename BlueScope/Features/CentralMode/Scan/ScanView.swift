import SwiftUI

struct ScanView: View {
    @StateObject private var viewModel: ScanViewModel
    private let centralManager: CentralManaging
    @State private var selectedPeripheral: DiscoveredPeripheral?

    init(centralManager: CentralManaging) {
        _viewModel = StateObject(wrappedValue: ScanViewModel(centralManager: centralManager))
        self.centralManager = centralManager
    }

    var body: some View {
        VStack(spacing: 0) {
            ScanStatusView(state: viewModel.scanState)
            Group {
                if viewModel.peripherals.isEmpty {
                    EmptyStateView(
                        systemImage: "wifi.slash",
                        title: "No devices found",
                        message: "Make sure nearby devices are powered on and advertising."
                    )
                } else {
                    List(viewModel.peripherals) { peripheral in
                        PeripheralRowView(peripheral: peripheral)
                            .frame(maxWidth: 600)
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.didSelect(peripheral)
                                selectedPeripheral = peripheral
                            }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Scan")
        .navigationDestination(item: $selectedPeripheral) { peripheral in
            DeviceDetailView(peripheral: peripheral, centralManager: centralManager)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(viewModel.scanState == .scanning ? "Stop" : "Start") {
                    viewModel.toggleScan()
                }
            }
        }
        .onAppear { viewModel.onAppear() }
        .onDisappear { viewModel.onDisappear() }
    }
}

private struct ScanStatusView: View {
    let state: ScanState

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var color: Color {
        switch state {
        case .scanning: return .statusConnected
        case .completed: return .statusWarning
        }
    }

    private var label: String {
        switch state {
        case .scanning: return "Scanning for devices"
        case .completed: return "Scanning completed"
        }
    }
}

/// Local, feature-scoped subview — not reused outside the scan list.
private struct PeripheralRowView: View {
    let peripheral: DiscoveredPeripheral

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: peripheral.deviceKind.systemImage)
                .font(.system(size: 18))
                .foregroundStyle(Color.accentPrimary)
                .frame(width: 36, height: 36)
                .background(Color.surfaceTertiary, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(peripheral.name ?? "Unknown Device")
                    .font(.bodyText)
                    .foregroundStyle(Color.textPrimary)
                Text("\(peripheral.rssi) dBm")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Image(systemName: "wifi", variableValue: peripheral.signalStrengthFraction)
                .font(.system(size: 18))
                .foregroundStyle(Color.accentPrimary)
        }
        .padding(12)
        .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        ScanView(centralManager: CentralManager())
    }
}
