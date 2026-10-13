//
//  ConfirmationCardModifier.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Card container shared by the booking confirmation sections.
struct ConfirmationCardModifier: ViewModifier {
    private enum Layout {
        static let borderWidth: CGFloat = 1
    }

    func body(content: Content) -> some View {
        content
            .padding(Spacing.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AlmatarColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xLarge)
                    .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
            )
    }
}

extension View {
    func confirmationCard() -> some View {
        modifier(ConfirmationCardModifier())
    }
}

/// Section title used at the top of each confirmation card.
struct ConfirmationSectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
            .foregroundStyle(AlmatarColors.textPrimaryStatic)
    }
}
