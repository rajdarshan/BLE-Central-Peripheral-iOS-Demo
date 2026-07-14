import SwiftUI

struct ConnectedCentralsView: View {
    @StateObject private var viewModel: ConnectedCentralsViewModel
    @State private var messageText = ""

    init(peripheralManager: PeripheralManaging) {
        _viewModel = StateObject(wrappedValue: ConnectedCentralsViewModel(peripheralManager: peripheralManager))
    }

    var body: some View {
        List {
            Section("Connected Centrals") {
                if viewModel.connectedCentrals.isEmpty {
                    Text("No centrals connected")
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    ForEach(viewModel.connectedCentrals) { central in
                        ConnectedCentralRow(central: central)
                    }
                }
            }

            Section("Request Log") {
                if viewModel.requestLog.isEmpty {
                    Text("No activity yet")
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                } else {
                    ForEach(viewModel.requestLog) { entry in
                        RequestLogRow(entry: entry)
                    }
                }
            }

            Section("Push Value") {
                TextField("Value", text: $messageText)
                Button("Send") {
                    viewModel.pushValue(messageText)
                    messageText = ""
                }
                .disabled(messageText.isEmpty)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Connected Centrals")
    }
}

/// Local, feature-scoped subview — not reused outside Connected Centrals.
private struct ConnectedCentralRow: View {
    let central: ConnectedCentral

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(central.id.uuidString)
                    .font(.captionText)
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                Text(central.lastActivity, style: .time)
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            if central.isSubscribed {
                Image(systemName: "bell.fill")
                    .foregroundStyle(Color.statusConnected)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Local, feature-scoped subview — not reused outside Connected Centrals.
private struct RequestLogRow: View {
    let entry: CentralRequestLogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.message)
                .font(.bodyText)
                .foregroundStyle(Color.textPrimary)
            Text(entry.timestamp, style: .time)
                .font(.captionText)
                .foregroundStyle(Color.textSecondary)
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        ConnectedCentralsView(peripheralManager: PeripheralManager())
    }
}
