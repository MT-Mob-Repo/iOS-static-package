//
//  CancellationPolicyView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// One row in the cancellation policy, ready for display.
struct CancellationPolicyTier: Identifiable, Hashable {
    enum Tone {
        case fullRefund
        case partialRefund
        case noRefund
    }

    let id: Int
    let title: String
    let window: String?
    let note: String?
    let tone: Tone
}

/// Collapsible card listing the refund tiers on a timeline.
/// Collapsed, it shows the first tier only.
struct CancellationPolicyView: View {
    private enum Layout {
        static let dotSize: CGFloat = 8
        /// Centers the dot on the first line of the tier title.
        static let dotTopInset: CGFloat = 6
        static let lineWidth: CGFloat = 1
        static let borderWidth: CGFloat = 1
        static let chevronSize: CGFloat = 14
        static let chevronUpIcon = "chevron.up"
        static let chevronDownIcon = "chevron.down"
    }

    let title: String
    let tiers: [CancellationPolicyTier]

    @State private var isExpanded: Bool

    init(title: String, tiers: [CancellationPolicyTier], startsExpanded: Bool = false) {
        self.title = title
        self.tiers = tiers
        _isExpanded = State(initialValue: startsExpanded)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            header

            VStack(alignment: .leading, spacing: Spacing.small) {
                ForEach(visibleTiers) { tierRow($0) }
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AlmatarColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xLarge)
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
        )
    }

    private var isExpandable: Bool { tiers.count > 1 }

    private var visibleTiers: [CancellationPolicyTier] {
        isExpanded ? tiers : Array(tiers.prefix(1))
    }

    // MARK: - Header

    private var header: some View {
        Button {
            withAnimation(.easeInOut) { isExpanded.toggle() }
        } label: {
            HStack(spacing: Spacing.small) {
                Text(title)
                    .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isExpandable {
                    Image(systemName: isExpanded ? Layout.chevronUpIcon : Layout.chevronDownIcon)
                        .font(.system(size: Layout.chevronSize, weight: Typography.Weight.semibold))
                        .foregroundStyle(AlmatarColors.iconPrimaryStatic)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isExpandable)
    }

    // MARK: - Tier

    private func tierRow(_ tier: CancellationPolicyTier) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            timelineMarker(color: dotColor(tier.tone))

            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(tier.title)
                    .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)

                if let window = tier.window {
                    Text(window)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let note = tier.note {
                    Text(note)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(noteColor(tier.tone))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Lets the timeline line stretch to the height of the text.
        .fixedSize(horizontal: false, vertical: true)
    }

    private func timelineMarker(color: Color) -> some View {
        VStack(spacing: Spacing.xxSmall) {
            Circle()
                .fill(color)
                .frame(width: Layout.dotSize, height: Layout.dotSize)
                .padding(.top, Layout.dotTopInset)

            Rectangle()
                .fill(AlmatarColors.borderDefaultCard)
                .frame(width: Layout.lineWidth)
                .frame(maxHeight: .infinity)
        }
        .frame(width: Layout.dotSize)
        .accessibilityHidden(true)
    }

    private func dotColor(_ tone: CancellationPolicyTier.Tone) -> Color {
        switch tone {
        case .fullRefund: return AlmatarColors.iconComplementaryGreen
        case .partialRefund: return AlmatarColors.iconComplementaryYellow
        case .noRefund: return AlmatarColors.textComplementaryRed
        }
    }

    private func noteColor(_ tone: CancellationPolicyTier.Tone) -> Color {
        switch tone {
        case .fullRefund: return AlmatarColors.textComplementaryGreen
        case .partialRefund: return AlmatarColors.textComplementaryYellow
        case .noRefund: return AlmatarColors.textComplementaryRed
        }
    }
}

#Preview {
    CancellationPolicyView(
        title: "Cancellation Policy",
        tiers: [
            CancellationPolicyTier(id: 0, title: "Free cancellation", window: "More than 48 hours before departure", note: "Cancel for a full refund.", tone: .fullRefund),
            CancellationPolicyTier(id: 1, title: "50% refund", window: "Less than 48 hours", note: "Half the amount is refunded.", tone: .partialRefund)
        ]
    )
    .padding(Spacing.screenHorizontal)
}
