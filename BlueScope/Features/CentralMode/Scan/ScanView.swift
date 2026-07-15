import SwiftUI

struct ScanView: View {
    @StateObject private var viewModel: ScanViewModel
    private let centralManager: CentralManaging
    @State private var selectedPeripheral: DiscoveredPeripheral?
    @State private var selectedFilter: DeviceKind?

    init(centralManager: CentralManaging) {
        _viewModel = StateObject(wrappedValue: ScanViewModel(centralManager: centralManager))
        self.centralManager = centralManager
    }

    private var filteredPeripherals: [DiscoveredPeripheral] {
        viewModel.peripherals.filter { selectedFilter == nil || $0.deviceKind == selectedFilter }
    }

    // swiftlint:disable:next large_tuple
    private var emptyStateContent: (systemImage: String, title: String, message: String) {
        if !viewModel.peripherals.isEmpty {
            return ("wifi.slash", "No matching devices", "Try a different filter.")
        }
        switch viewModel.scanState {
        case .scanning:
            return ("antenna.radiowaves.left.and.right", "Searching for devices", "Nearby Bluetooth devices will appear here.")
        case .completed:
            return ("wifi.slash", "No devices found", "Make sure nearby devices are powered on and advertising.")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScanStatusView(state: viewModel.scanState)
            List {
                if filteredPeripherals.isEmpty {
                    EmptyStateView(
                        systemImage: emptyStateContent.systemImage,
                        title: emptyStateContent.title,
                        message: emptyStateContent.message
                    )
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(filteredPeripherals) { peripheral in
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
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .refreshable {
                if viewModel.scanState == .completed {
                    viewModel.toggleScan()
                }
                try? await Task.sleep(for: .seconds(1))
            }
        }
        .background(Color.surfaceSecondary)
        .navigationTitle("Scan")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $selectedPeripheral) { peripheral in
            DeviceDetailView(peripheral: peripheral, centralManager: centralManager)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        selectedFilter = nil
                    } label: {
                        if selectedFilter == nil {
                            Label("All Devices", systemImage: "checkmark")
                        } else {
                            Text("All Devices")
                        }
                    }
                    Button {
                        selectedFilter = .heartRate
                    } label: {
                        if selectedFilter == .heartRate {
                            Label("Heart Rate", systemImage: "checkmark")
                        } else {
                            Text("Heart Rate")
                        }
                    }
                    Button {
                        selectedFilter = .genericHardware
                    } label: {
                        if selectedFilter == .genericHardware {
                            Label("Generic Hardware", systemImage: "checkmark")
                        } else {
                            Text("Generic Hardware")
                        }
                    }
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(selectedFilter == nil ? Color.textPrimary : Color.accentPrimary)
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surfaceSecondary)
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
                .foregroundStyle(Color.textPrimary)
                .frame(width: 36, height: 36)

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
        .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderDefault, lineWidth: 1))
    }
}

#Preview {
    NavigationStack {
        ScanView(centralManager: CentralManager())
    }

    PeripheralRowView(peripheral: DiscoveredPeripheral(id: UUID(), rssi: 45, lastSeen: Date(), isConnectable: true))
}
