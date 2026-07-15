import SwiftUI

/// Full-width outlined button — no fill, colored border and label text.
/// Reused wherever a primary screen action is reversible or non-destructive
/// (Disconnect, Read Once, Write) and shouldn't compete visually with a
/// filled/tinted button.
struct OutlinedButton: View {
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bodyText)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: 1))
    }
}

#Preview {
    VStack(spacing: 16) {
        OutlinedButton(title: "Disconnect", color: .statusError) {}
        OutlinedButton(title: "Read Once", color: .textPrimary) {}
        OutlinedButton(title: "Write", color: .accentPrimary) {}
    }
    .padding()
}
