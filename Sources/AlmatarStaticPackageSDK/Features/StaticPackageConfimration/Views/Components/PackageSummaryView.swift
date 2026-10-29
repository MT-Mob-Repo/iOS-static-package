//
//  PackageSummaryView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// A label / value row in the package summary.
struct PackageSummaryRow: Hashable {
    let label: String
    let value: String
    /// Shows the value as a highlighted pill (e.g. the park access).
    var isBadge: Bool = false
}

/// Label / value rows, the items included in the package and the add-ons the customer picked.
struct PackageSummaryView: View {
    private enum Layout {
        static let iconSize: CGFloat = 18
        static let iconContainerSize: CGFloat = 32
    }

    let title: String
    let rows: [PackageSummaryRow]
    let includesTitle: String
    let includes: [JourneySnapshotItem]
    let addonsTitle: String
    let addons: [JourneySnapshotItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            ConfirmationSectionTitle(title: title)

            VStack(spacing: Spacing.small) {
                ForEach(rows, id: \.self) { rowView($0) }
            }

            if !includes.isEmpty {
                itemsList(title: includesTitle, items: includes)
            }

            if !addons.isEmpty {
                ConfirmationDivider()
                itemsList(title: addonsTitle, items: addons)
            }
        }
        .confirmationCard()
    }

    private func rowView(_ row: PackageSummaryRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(row.label)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)

            Spacer(minLength: Spacing.small)

            if row.isBadge {
                ConfirmationSuccessBadge(title: row.value, showsCheckmark: true)
            } else {
                Text(row.value)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func itemsList(title: String, items: [JourneySnapshotItem]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)

            ForEach(items) { item in
                HStack(spacing: Spacing.small) {
                    RemoteIconView(icon: item.iconName, size: Layout.iconSize, tint: AlmatarColors.iconPrimaryInteractive)
                        .frame(width: Layout.iconContainerSize, height: Layout.iconContainerSize)
                        .background(AlmatarColors.surfaceBrandSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))

                    Text(item.label)
                        .modifier(AppTextModifier(size: Typography.Size.regular))
                        .foregroundStyle(AlmatarColors.textPrimaryStatic)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
}
