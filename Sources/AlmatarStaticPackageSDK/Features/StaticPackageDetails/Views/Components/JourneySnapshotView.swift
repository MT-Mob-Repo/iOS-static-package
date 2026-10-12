//
//  JourneySnapshotView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Card listing the package highlights. Full-width items take a whole row;
/// the rest are laid out two per row.
struct JourneySnapshotView: View {
    private enum Layout {
        static let iconSize: CGFloat = 24
        static let tileMinHeight: CGFloat = 56
        static let borderWidth: CGFloat = 1
    }

    let title: String
    let items: [JourneySnapshotItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            VStack(spacing: Spacing.small) {
                ForEach(rows.indices, id: \.self) { index in
                    rowView(rows[index])
                }
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AlmatarColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xLarge)
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: 1)
        )
    }

    // MARK: - Rows

    /// Groups items into rows: a full-width item alone, other items in pairs.
    private var rows: [[JourneySnapshotItem]] {
        var rows: [[JourneySnapshotItem]] = []
        var pending: JourneySnapshotItem?

        for item in items {
            if item.isFullWidth {
                if let half = pending {
                    rows.append([half])
                    pending = nil
                }
                rows.append([item])
            } else if let half = pending {
                rows.append([half, item])
                pending = nil
            } else {
                pending = item
            }
        }
        if let half = pending {
            rows.append([half])
        }
        return rows
    }

    @ViewBuilder
    private func rowView(_ row: [JourneySnapshotItem]) -> some View {
        if let item = row.first, item.isFullWidth {
            tile(item)
        } else {
            HStack(spacing: Spacing.small) {
                ForEach(row) { tile($0) }
                // Keep a lone half-width item at half width.
                if row.count == 1 {
                    Color.clear.frame(maxWidth: .infinity)
                }
            }
            // Both tiles in a row share the height of the taller one.
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func tile(_ item: JourneySnapshotItem) -> some View {
        HStack(spacing: Spacing.small) {
            RemoteIconView(icon: item.icon, size: Layout.iconSize, tint: AlmatarColors.iconPrimaryStatic)

            Text(item.title)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .frame(maxWidth: .infinity, minHeight: Layout.tileMinHeight, maxHeight: .infinity, alignment: .leading)
        .background(AlmatarColors.surfaceCardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

#Preview {
    JourneySnapshotView(title: "Journey Snapshot", items: JourneySnapshotItem.mockItems)
        .padding(Spacing.screenHorizontal)
}
