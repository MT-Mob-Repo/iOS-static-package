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
    /// Shows the value as a highlighted pill (e.g. the package tier).
    var isBadge: Bool = false
}

/// Hero image, label / value rows and the list of items included in the package.
struct PackageSummaryView: View {
    private enum Layout {
        static let imageHeight: CGFloat = 160
        static let includeIconSize: CGFloat = 18
        static let includeIconContainerSize: CGFloat = 32
        static let borderWidth: CGFloat = 1
        static let badgeBackgroundOpacity: Double = 0.08
    }

    let title: String
    let rows: [PackageSummaryRow]
    let includesTitle: String
    let includes: [JourneySnapshotItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            ConfirmationSectionTitle(title: title)

            VStack(spacing: Spacing.small) {
                ForEach(rows, id: \.self) { rowView($0) }
            }

            if !includes.isEmpty {
                Rectangle()
                    .fill(AlmatarColors.borderDefaultCard)
                    .frame(height: Layout.borderWidth)

                includesList
            }
        }
        .confirmationCard()
    }

    private func heroImage(_ url: URL) -> some View {
        // Fixed-size container so a filled image never widens the card.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: Layout.imageHeight)
            .overlay(
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    default:
                        AlmatarColors.surfaceCardSecondary
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .accessibilityHidden(true)
    }

    private func rowView(_ row: PackageSummaryRow) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(row.label)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)

            Spacer(minLength: Spacing.small)

            if row.isBadge {
                badge(row.value)
            } else {
                Text(row.value)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .multilineTextAlignment(.trailing)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func badge(_ value: String) -> some View {
        Text(value.uppercased())
            .modifier(AppTextModifier(size: Typography.Size.xSmall, fontWeight: Typography.Weight.medium))
            .foregroundStyle(AlmatarColors.textComplementaryGreen)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xxxSmall)
            .background(AlmatarColors.surfaceSuccessLight)
            .clipShape(Capsule())
    }

    private var includesList: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(includesTitle)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)

            ForEach(includes, id: \.self) { item in
                HStack(spacing: Spacing.small) {
                    RemoteIconView(icon: item.iconName, size: Layout.includeIconSize, tint: AlmatarColors.iconPrimaryInteractive)
                        .frame(width: Layout.includeIconContainerSize, height: Layout.includeIconContainerSize)
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
