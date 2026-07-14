import SwiftUI

/// Renders a single R/W/N capability badge for a BLE characteristic property.
/// Reused wherever characteristic/service capabilities need a compact visual
/// tag (Device Detail's characteristic rows, Advertise's Echo Service block).
struct PropertyBadge: View {
    let label: String
    let background: Color
    let foreground: Color

    var body: some View {
        Text(label)
            .font(.captionText)
            .foregroundStyle(foreground)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(background, in: Capsule())
    }
}

#Preview {
    HStack(spacing: 6) {
        PropertyBadge(label: "R", background: .badgeReadBg, foreground: .badgeReadText)
        PropertyBadge(label: "W", background: .badgeWriteBg, foreground: .badgeWriteText)
        PropertyBadge(label: "N", background: .badgeNotifyBg, foreground: .badgeNotifyText)
    }
    .padding()
}
