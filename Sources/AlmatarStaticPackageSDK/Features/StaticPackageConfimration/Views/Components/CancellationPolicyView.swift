//
//  CancellationPolicyView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// One cancellation window with its refund.
struct CancellationPolicyItem: Hashable {
    let window: String?
    let note: String?
    /// Already localized, e.g. "100% refund".
    let refundTitle: String
    let isFullRefund: Bool
}

/// Collapsible card: the refund status and the first window when collapsed,
/// every window with its refund when expanded.
struct CancellationPolicyView: View {
    private enum Layout {
        static let chevronIcon = "chevron.down"
        static let chevronSize: CGFloat = 14
        static let expandedRotation: Double = 180
        static let statusDotSize: CGFloat = 8
        // TODO: Replace with the design-system success color once available.
        static let refundTint = AlmatarColors.iconComplementaryGreen
        static let refundBackgroundOpacity: Double = 0.08
        static let borderWidth: CGFloat = 1
    }

    let title: String
    let statusTitle: String
    let isRefundable: Bool
    let items: [CancellationPolicyItem]

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            header

            statusRow

            if isExpanded {
                VStack(spacing: Spacing.small) {
                    ForEach(items, id: \.self) { itemView($0) }
                }
                .transition(.opacity)
            } else if let first = items.first {
                windowText(first)
                    .padding(.leading, Layout.statusDotSize + Spacing.xSmall)
            }
        }
        .confirmationCard()
    }

    private var header: some View {
        Button {
            withAnimation(.easeInOut) { isExpanded.toggle() }
        } label: {
            HStack(spacing: Spacing.small) {
                ConfirmationSectionTitle(title: title)
                Spacer(minLength: Spacing.small)
                if !items.isEmpty {
                    Image(systemName: Layout.chevronIcon)
                        .font(.system(size: Layout.chevronSize, weight: Typography.Weight.semibold))
                        .foregroundStyle(AlmatarColors.iconPrimaryStatic)
                        .rotationEffect(.degrees(isExpanded ? Layout.expandedRotation : 0))
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(items.isEmpty)
        .accessibilityAddTraits(.isHeader)
    }

    private var statusRow: some View {
        let tint = isRefundable ? Layout.refundTint : AlmatarColors.textSecondaryStatic
        return HStack(spacing: Spacing.xSmall) {
            Circle()
                .fill(tint)
                .frame(width: Layout.statusDotSize, height: Layout.statusDotSize)
                .accessibilityHidden(true)
            Text(statusTitle)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(tint)
        }
    }

    @ViewBuilder
    private func windowText(_ item: CancellationPolicyItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxSmall) {
            if let window = item.window {
                Text(window)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let note = item.note {
                Text(note)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func itemView(_ item: CancellationPolicyItem) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            windowText(item)
                .frame(maxWidth: .infinity, alignment: .leading)

            refundPill(item)
        }
        .padding(Spacing.small)
        .background(AlmatarColors.surfaceCardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

    private func refundPill(_ item: CancellationPolicyItem) -> some View {
        let tint = item.isFullRefund ? Layout.refundTint : AlmatarColors.textPrimaryStatic
        return Text(item.refundTitle)
            .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xxxSmall)
            .background(tint.opacity(Layout.refundBackgroundOpacity))
            .clipShape(Capsule())
    }
}

#Preview {
    CancellationPolicyView(
        title: "Cancellation Policy",
        statusTitle: "Free cancellation",
        isRefundable: true,
        items: [
            CancellationPolicyItem(window: "More than 48 hours before departure", note: "Cancel for a full refund.", refundTitle: "100% refund", isFullRefund: true),
            CancellationPolicyItem(window: "Less than 48 hours", note: "Half the amount is refunded.", refundTitle: "50% refund", isFullRefund: false)
        ]
    )
    .padding(Spacing.screenHorizontal)
}
