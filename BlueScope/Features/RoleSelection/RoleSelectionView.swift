import SwiftUI

struct RoleSelectionView: View {
    @StateObject private var viewModel: RoleSelectionViewModel
    @State private var path = NavigationPath()
    private let roleManager: RoleManager

    init(roleManager: RoleManager) {
        _viewModel = StateObject(wrappedValue: RoleSelectionViewModel(roleManager: roleManager))
        self.roleManager = roleManager
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 16) {
                RoleCard(
                    role: .central,
                    isSelected: viewModel.selectedRole == .central,
                    isDisabled: viewModel.isSwitchingRole
                ) {
                    selectRole(.central)
                }

                RoleCard(
                    role: .peripheral,
                    isSelected: viewModel.selectedRole == .peripheral,
                    isDisabled: viewModel.isSwitchingRole
                ) {
                    selectRole(.peripheral)
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.captionText)
                        .foregroundStyle(Color.statusError)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("BlueScope")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: AppRole.self) { role in
                switch role {
                case .central:
                    ScanView(centralManager: roleManager.centralManager)
                case .peripheral:
                    AdvertiseView(peripheralManager: roleManager.peripheralManager)
                }
            }
        }
    }

    private func selectRole(_ role: AppRole) {
        Task {
            if await viewModel.selectRole(role) {
                path.append(role)
            }
        }
    }
}

/// Local, feature-scoped subview — not reused outside role selection.
private struct RoleCard: View {
    let role: AppRole
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: role.sfSymbolName)
                    .font(.system(size: 28))
                    .foregroundStyle(isSelected ? Color.accentPrimary : Color.textSecondary)
                    .frame(width: 44)

                VStack(alignment: .leading, spacing: 4) {
                    Text(role.title)
                        .font(.bodyText)
                        .foregroundStyle(Color.textPrimary)
                        .lineLimit(1)
                    Text(role.subtitle)
                        .font(.captionText)
                        .foregroundStyle(Color.textSecondary)
                        .lineLimit(2, reservesSpace: true)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentPrimary)
                }
            }
            .padding()
            .background(Color.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentPrimary : Color.borderDefault, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.5 : 1)
    }
}

#Preview {
    RoleSelectionView(roleManager: RoleManager())
}
