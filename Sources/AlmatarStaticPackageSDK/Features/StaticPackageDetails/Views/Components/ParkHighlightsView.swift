//
//  ParkHighlightsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Section title followed by a two-column grid of highlight cards.
struct ParkHighlightsView: View {
    private enum Layout {
        static let columnsCount = 2
        static let iconSize: CGFloat = 24
        static let cardMinHeight: CGFloat = 124
        static let borderWidth: CGFloat = 1
        static let titleLineLimit = 2
    }

    let title: String
    let items: [ParkHighlightItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            VStack(spacing: Spacing.small) {
                ForEach(rows.indices, id: \.self) { index in
                    HStack(spacing: Spacing.small) {
                        ForEach(rows[index]) { card($0) }
                        // Keep a lone card at half width.
                        if rows[index].count < Layout.columnsCount {
                            Color.clear.frame(maxWidth: .infinity)
                        }
                    }
                    // Both cards in a row share the height of the taller one.
                    .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var rows: [[ParkHighlightItem]] {
        stride(from: 0, to: items.count, by: Layout.columnsCount).map {
            Array(items[$0..<min($0 + Layout.columnsCount, items.count)])
        }
    }

    private func card(_ item: ParkHighlightItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.zero) {
            RemoteIconView(icon: item.icon, size: Layout.iconSize)

            Spacer(minLength: Spacing.xSmall)

            Text(item.label)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)

            Text(item.value)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(Layout.titleLineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, minHeight: Layout.cardMinHeight, maxHeight: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xLarge)
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: 1)
        )
    }
}

#Preview {
    ParkHighlightsView(title: "Park Highlights", items: ParkHighlightItem.mockItems)
        .padding(Spacing.screenHorizontal)
}
