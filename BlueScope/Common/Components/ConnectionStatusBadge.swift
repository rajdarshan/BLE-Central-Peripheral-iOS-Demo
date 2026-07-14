import SwiftUI

/// Renders a ConnectionState as an icon + label pair. Reused wherever a
/// central's connection lifecycle needs to be shown (currently Device Detail).
struct ConnectionStatusBadge: View {
    let state: ConnectionState

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
        switch state {
        case .disconnected: return "xmark.circle"
        case .connecting, .discoveringServices: return "arrow.triangle.2.circlepath"
        case .connected: return "checkmark.circle.fill"
        case .failed: return "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch state {
        case .disconnected: return .statusDisconnected
        case .connecting, .discoveringServices: return .statusWarning
        case .connected: return .statusConnected
        case .failed: return .statusError
        }
    }

    private var label: String {
        switch state {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting…"
        case .discoveringServices: return "Discovering services…"
        case .connected: return "Connected"
        case .failed(let error): return error.localizedDescription
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        ConnectionStatusBadge(state: .disconnected)
        ConnectionStatusBadge(state: .connecting)
        ConnectionStatusBadge(state: .discoveringServices)
        ConnectionStatusBadge(state: .connected(services: []))
        ConnectionStatusBadge(state: .failed(.connectionTimeout))
    }
    .padding()
}
