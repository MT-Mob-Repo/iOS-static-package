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

/// Section title used at the top of each confirmation card, with an optional leading SF Symbol.
struct ConfirmationSectionTitle: View {
    private enum Layout {
        static let iconSize: CGFloat = 18
    }

    let title: String
    var icon: String? = nil

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: Layout.iconSize, weight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.iconPrimaryStatic)
                    .accessibilityHidden(true)
            }
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
        }
        .accessibilityAddTraits(.isHeader)
    }
}

/// Thin separator between groups inside a confirmation card.
struct ConfirmationDivider: View {
    var body: some View {
        Rectangle()
            .fill(AlmatarColors.borderDefaultCard)
            .frame(height: 1)
    }
}

/// Green uppercase pill, e.g. "VIP ACCESS", "VERIFIED", "PAID IN FULL".
struct ConfirmationSuccessBadge: View {
    private enum Layout {
        static let checkmarkIcon = "checkmark"
        static let checkmarkSize: CGFloat = 8
    }

    let title: String
    var showsCheckmark: Bool = false

    var body: some View {
        HStack(spacing: Spacing.xxSmall) {
            if showsCheckmark {
                Image(systemName: Layout.checkmarkIcon)
                    .font(.system(size: Layout.checkmarkSize, weight: Typography.Weight.bold))
                    .accessibilityHidden(true)
            }
            Text(title.uppercased())
                .modifier(AppTextModifier(size: Typography.Size.xSmall, fontWeight: Typography.Weight.medium))
                .lineLimit(1)
        }
        .foregroundStyle(AlmatarColors.textComplementaryGreen)
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.xxxSmall)
        .background(AlmatarColors.surfaceSuccessLight)
        .clipShape(Capsule())
    }
}

/// Small grey caption above a value, e.g. "Check-in" over "Thu 16 Jul 2026".
struct ConfirmationLabeledValue: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            Text(label)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
            Text(value)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
