//
//  JourneySnapshotView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Card listing the package highlights. The first item (usually the location) takes the whole row;
/// the rest are two per row, and a last item on its own keeps half the width.
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
                    rowView(rows[index], isFirst: index == 0)
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

    /// The first item alone, then the rest in pairs.
    private var rows: [[JourneySnapshotItem]] {
        var remaining = items[...]
        var rows: [[JourneySnapshotItem]] = []
        if let first = remaining.popFirst() {
            rows.append([first])
        }
        while !remaining.isEmpty {
            rows.append(Array(remaining.prefix(2)))
            remaining = remaining.dropFirst(2)
        }
        return rows
    }

    @ViewBuilder
    private func rowView(_ row: [JourneySnapshotItem], isFirst: Bool) -> some View {
        if isFirst, let item = row.first {
            tile(item)
        } else {
            HStack(spacing: Spacing.small) {
                ForEach(row) { tile($0) }
                // Keeps a lone last item at half width.
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
            RemoteIconView(icon: item.icon, size: Layout.iconSize)

            Text(item.label)
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
