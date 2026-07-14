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
        Form {
            Section {
                Picker("Format", selection: $viewModel.selectedFormat) {
                    ForEach(ValueFormat.allCases) { format in
                        Text(format.label).tag(format)
                    }
                }
                .pickerStyle(.segmented)

                Text(viewModel.latestValue?.formatted(as: viewModel.selectedFormat) ?? "—")
                    .font(.monospaceValue)
                    .foregroundStyle(Color.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.surfaceSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.borderDefault, lineWidth: 1)
                    )

                if viewModel.characteristic.properties.contains(.read) {
                    Button("Read Once") {
                        Task { await viewModel.readOnce() }
                    }
                }
            }

            if viewModel.characteristic.properties.contains(.notify) {
                Section {
                    Toggle("Notifications", isOn: Binding(
                        get: { viewModel.notificationsEnabled },
                        set: { newValue in
                            Task { await viewModel.setNotificationsEnabled(newValue) }
                        }
                    ))
                }
            }

            if viewModel.characteristic.properties.contains(.write) {
                Section("Write Value") {
                    TextField("Value", text: $writeText)
                    Button("Write") {
                        Task {
                            await viewModel.write(writeText)
                            writeText = ""
                        }
                    }
                    .disabled(writeText.isEmpty)
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(.captionText)
                    .foregroundStyle(Color.statusError)
            }
        }
        .navigationTitle(viewModel.characteristic.name)
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
