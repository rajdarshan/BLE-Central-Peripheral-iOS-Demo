import SwiftUI
import CoreBluetooth

struct CharacteristicDetailView: View {
    @StateObject private var viewModel: CharacteristicDetailViewModel
    @State private var writeText = ""

    init(characteristic: DiscoveredCharacteristic, serviceID: CBUUID, centralManager: CentralManaging) {
        _viewModel = StateObject(wrappedValue: CharacteristicDetailViewModel(
            characteristic: characteristic,
            serviceID: serviceID,
            centralManager: centralManager
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Live Value")
                        .font(.sectionHeader)
                        .foregroundStyle(Color.textSecondary)
                        .textCase(.uppercase)

                    VStack(spacing: 4) {
                        Text(viewModel.latestValue?.formatted(as: viewModel.selectedFormat) ?? "—")
                            .font(.valueDisplay)
                            .foregroundStyle(Color.accentPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2...)

                        if let latestValue = viewModel.latestValue {
                            Text(updatedText(for: latestValue.receivedAt))
                                .font(.captionText)
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 20)
                    .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderDefault, lineWidth: 1))
                }

                if viewModel.characteristic.properties.contains(.notify) {
                    Toggle("Notifications", isOn: Binding(
                        get: { viewModel.notificationsEnabled },
                        set: { newValue in
                            Task { await viewModel.setNotificationsEnabled(newValue) }
                        }
                    ))
                    .font(.bodyText)
                    .foregroundStyle(Color.textPrimary)
                    .padding(12)
                    .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderDefault, lineWidth: 1))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Format")
                        .font(.sectionHeader)
                        .foregroundStyle(Color.textSecondary)
                        .textCase(.uppercase)

                    HStack(spacing: 8) {
                        ForEach(ValueFormat.allCases) { format in
                            FormatPillButton(
                                format: format,
                                isSelected: viewModel.selectedFormat == format
                            ) {
                                viewModel.selectedFormat = format
                            }
                        }
                    }
                }

                if viewModel.characteristic.properties.contains(.write) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Write Value")
                            .font(.sectionHeader)
                            .foregroundStyle(Color.textSecondary)
                            .textCase(.uppercase)

                        TextField("Value", text: $writeText)
                            .font(.bodyText)
                            .padding(12)
                            .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderDefault, lineWidth: 1))

                        OutlinedButton(title: "Write", color: .accentPrimary) {
                            Task {
                                await viewModel.write(writeText)
                                writeText = ""
                            }
                        }
                        .disabled(writeText.isEmpty)
                        .opacity(writeText.isEmpty ? 0.5 : 1)
                    }
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.captionText)
                        .foregroundStyle(Color.statusError)
                }
            }
            .padding(16)
        }
        .background(Color.surfaceSecondary)
        .navigationTitle(viewModel.characteristic.name)
        .navigationSubtitle("0x\(viewModel.characteristic.id.uuidString)")
        .safeAreaInset(edge: .bottom) {
            if viewModel.characteristic.properties.contains(.read) {
                OutlinedButton(title: "Read Once", color: .textPrimary) {
                    Task { await viewModel.readOnce() }
                }
                .padding(16)
                .background(Color.surfaceSecondary)
            }
        }
    }

    private func updatedText(for date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        switch seconds {
        case ..<1: return "Updated just now"
        case ..<60: return "Updated \(seconds)s ago"
        case ..<3600: return "Updated \(seconds / 60)m ago"
        default: return "Updated \(seconds / 3600)h ago"
        }
    }
}

/// Local, feature-scoped subview — a tappable pill representing one
/// ValueFormat option, shown selected via a border rather than a fill so it
/// stays visually quiet next to the hero value display above it.
private struct FormatPillButton: View {
    let format: ValueFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(format.label)
                .font(.captionText)
                .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .overlay(
                    Capsule().stroke(isSelected ? Color.borderDefault : Color.clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CharacteristicDetailView(
            characteristic: DiscoveredCharacteristic(
                id: CBUUID(string: "2A19"),
                name: "Battery Level",
                properties: [.read, .notify],
                latestValue: CharacteristicValue(data: Data([0x5A]))
            ),
            serviceID: CBUUID(string: "180F"),
            centralManager: CentralManager()
        )
    }
}
