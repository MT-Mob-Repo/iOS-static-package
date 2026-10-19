//
//  CancellationPolicyView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// One row in the cancellation policy, ready for display.
public struct CancellationPolicyTier: Identifiable, Hashable, Sendable {
    public let id: Int
    /// e.g. "Free cancellation".
    public let title: String
    /// e.g. "30+ days before departure until 2026-04-17".
    public let window: String?
    /// e.g. "Full refund, except visa fee".
    public let note: String?

    public init(id: Int, title: String, window: String? = nil, note: String? = nil) {
        self.id = id
        self.title = title
        self.window = window
        self.note = note
    }
}

/// Collapsible card listing the refund tiers on a timeline.
/// Collapsed, it shows the first tier only.
public struct PackageCancellationPolicyView: View {
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

    /// - Parameters:
    ///   - title: The card title, e.g. "Cancellation Policy".
    ///   - tiers: The refund tiers, earliest cancellation window first.
    ///   - startsExpanded: Whether the tiers are visible when the card first appears.
    public init(title: String, tiers: [CancellationPolicyTier], startsExpanded: Bool = false) {
        self.title = title
        self.tiers = tiers
        _isExpanded = State(initialValue: startsExpanded)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            header
            if !visibleTiers.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    ForEach(visibleTiers) { tierRow($0) }
                }
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

    private var isExpandable: Bool { return true }

    private var visibleTiers: [CancellationPolicyTier] {
        isExpanded ? tiers : []
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
            timelineMarker(color: AlmatarColors.textComplementaryGreen)

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
                        .foregroundStyle(AlmatarColors.textComplementaryGreen)
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
}
