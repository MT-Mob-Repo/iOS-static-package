//
//  PrimaryButton.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI

/// Full-width, capsule-shaped primary button.
struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    init(_ title: String, isLoading: Bool = false, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AlmatarColors.textOnSurfacePrimary))
            } else {
                Text(title)
                    .font(Typography.button)
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isDisabled)
        .allowsHitTesting(!isLoading)
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.medium)
            .foregroundStyle(isEnabled ? AlmatarColors.textOnSurfacePrimary : AlmatarColors.textOnSurfacePrimaryDisabled)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.spring(), value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if !isEnabled { return AlmatarColors.surfacePrimaryDisabled }
        return isPressed ? AlmatarColors.surfacePrimaryPressed : AlmatarColors.surfacePrimaryBase
    }
}
