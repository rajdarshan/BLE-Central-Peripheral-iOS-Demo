import SwiftUI

/// Generic "nothing to show yet" placeholder, reused wherever a list can be
/// legitimately empty (no devices found, no centrals connected, etc.).
struct EmptyStateView: View {
    let systemImage: String
    let title: String
    var message: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 40))
                .foregroundStyle(Color.textSecondary)

            Text(title)
                .font(.bodyText)
                .foregroundStyle(Color.textPrimary)

            if let message {
                Text(message)
                    .font(.captionText)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        systemImage: "wifi.slash",
        title: "No devices found",
        message: "Make sure nearby devices are powered on and advertising."
    )
}
