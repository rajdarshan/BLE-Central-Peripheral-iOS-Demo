import SwiftUI

struct ConnectedCentralsView: View {
    @StateObject private var viewModel: ConnectedCentralsViewModel
    @State private var messageText = ""

    init(peripheralManager: PeripheralManaging) {
        _viewModel = StateObject(wrappedValue: ConnectedCentralsViewModel(peripheralManager: peripheralManager))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if viewModel.connectedCentrals.isEmpty {
                    EmptyStateView(systemImage: "dot.radiowaves.left.and.right", title: "No centrals connected")
                } else {
                    VStack(spacing: 12) {
                        ForEach(viewModel.connectedCentrals) { central in
                            ConnectedCentralRow(central: central)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Request Log")
                        .font(.sectionHeader)
                        .foregroundStyle(Color.textSecondary)
                        .textCase(.uppercase)

                    if viewModel.requestLog.isEmpty {
                        Text("No activity yet")
                            .font(.captionText)
                            .foregroundStyle(Color.textSecondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(viewModel.requestLog) { entry in
                                RequestLogRow(entry: entry)
                            }
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Color.surfaceSecondary)
        .navigationTitle("Connected Centrals")
        .safeAreaInset(edge: .bottom) {
            HStack(spacing: 12) {
                TextField("Value to push", text: $messageText)
                    .font(.bodyText)
                    .foregroundStyle(Color.textPrimary)
                    .padding(12)
                    .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderDefault, lineWidth: 1))

                Button {
                    viewModel.pushValue(messageText)
                    messageText = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(Color.accentPrimary)
                        .frame(width: 44, height: 44)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.accentPrimary, lineWidth: 1))
                }
                .disabled(messageText.isEmpty)
                .opacity(messageText.isEmpty ? 0.5 : 1)
            }
            .padding(16)
            .background(Color.surfaceSecondary)
        }
    }
}

/// Local, feature-scoped subview — a card for one connected central showing
/// a generic device icon (no per-device type data exists), its UUID, and
/// its subscription status.
private struct ConnectedCentralRow: View {
    let central: ConnectedCentral

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "iphone")
                .font(.system(size: 16))
                .foregroundStyle(Color.textPrimary)
                .frame(width: 36, height: 36)
                .background(Color.surfaceSecondary, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(central.id.uuidString)
                    .font(.bodyText.bold())
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Text(central.isSubscribed ? "Subscribed to notify" : "Read only")
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
            }

            Spacer()

            Circle()
                .fill(Color.statusConnected)
                .frame(width: 8, height: 8)
        }
        .padding(12)
        .background(Color.surfacePrimary, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.borderDefault, lineWidth: 1))
    }
}

/// Local, feature-scoped subview — not reused outside Connected Centrals.
private struct RequestLogRow: View {
    let entry: CentralRequestLogEntry

    var body: some View {
        Text("\(timeString) \(entry.message)")
            .font(.monospaceValue)
            .foregroundStyle(Color.textPrimary)
    }

    private var timeString: String {
        entry.timestamp.formatted(
            .dateTime.hour(.twoDigits(amPM: .omitted)).minute(.twoDigits).second(.twoDigits)
        )
    }
}

#Preview {
    NavigationStack {
        ConnectedCentralsView(peripheralManager: PeripheralManager())
    }
    
    ConnectedCentralRow(central: ConnectedCentral(id: UUID(), isSubscribed: true, lastActivity: Date()))
}
