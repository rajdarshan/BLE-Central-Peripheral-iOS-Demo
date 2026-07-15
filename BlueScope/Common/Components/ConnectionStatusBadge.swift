import SwiftUI

/// Renders a ConnectionState as a text pill, background tinted to the
/// status color. Reused wherever a central's connection lifecycle needs to
/// be shown (currently Device Detail).
struct ConnectionStatusBadge: View {
    let state: ConnectionState

    var body: some View {
        Text(label)
            .font(.bodyText)
            .foregroundStyle(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(color.opacity(0.15), in: Capsule())
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
