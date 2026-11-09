//
//  PaymentDetailsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Priced lines grouped by section, the total paid and how it was paid.
struct PaymentDetailsView: View {
    private enum Layout {
        static let cardIcon = "creditcard"
        static let cardIconSize: CGFloat = 14
    }

    let title: String
    /// Titles of the products included in the package price, e.g. "Round-trip flight", "Radisson Blu Hotel".
    /// Each is shown with `includedTitle` instead of an amount.
    var includedProducts: [String] = []
    let sections: [PriceBreakdownSection]
    /// Shown instead of an amount of zero, e.g. "Included".
    let includedTitle: String
    /// Formats an amount with the payment currency, e.g. "SAR 300".
    let amountText: (Double) -> String
    let totalTitle: String
    let total: String
    /// e.g. "Paid via Visa ending 4629".
    var paidViaText: String? = nil
    /// e.g. "Paid in full"; hidden when `nil`.
    var paidStatusTitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            ConfirmationSectionTitle(title: title)

            if !includedProducts.isEmpty || !sections.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.small) {
                    ForEach(includedProducts.indices, id: \.self) { index in
                        includedProductView(includedProducts[index])
                    }
                    ForEach(sections.indices, id: \.self) { index in
                        // The first section is the package price itself and reads better without a heading.
                        sectionView(sections[index], showsTitle: index > 0)
                    }
                }

                ConfirmationDivider()
            }

            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Text(totalTitle)
                    .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)

                Spacer(minLength: Spacing.small)

                SUITextPrice(text: total, modifier: AppTextModifier(size: Typography.Size.xLarge, fontWeight: Typography.Weight.bold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }

            if paidViaText != nil || paidStatusTitle != nil {
                paymentStatus
            }
        }
        .confirmationCard()
    }

    @ViewBuilder
    private func sectionView(_ section: PriceBreakdownSection, showsTitle: Bool) -> some View {
        if showsTitle, let title = Optional(section.title).nonEmpty {
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .padding(.top, Spacing.xxSmall)
        }
        ForEach(visibleItems(of: section), id: \.self) { itemView($0) }
    }

    /// Zero-amount lines are package products; when those are listed as `includedProducts`, skip them here to avoid duplicates.
    private func visibleItems(of section: PriceBreakdownSection) -> [PriceBreakdownItem] {
        let items = section.items ?? []
        return includedProducts.isEmpty ? items : items.filter { $0.amount != 0 }
    }

    /// e.g. "Radisson Blu Hotel ........ Included".
    private func includedProductView(_ productTitle: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            Text(productTitle)
                .modifier(AppTextModifier(size: Typography.Size.small))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Spacing.small)

            Text(includedTitle)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(1)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .combine)
    }

    private func itemView(_ item: PriceBreakdownItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(item.label)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = item.description.nonEmpty {
                    Text(subtitle)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: Spacing.small)

            if item.amount == 0 {
                Text(includedTitle)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            } else {
                SUITextPrice(text: amountText(item.amount), modifier: AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }
        }
    }

    /// "Paid via Visa ending 4629" with the "PAID IN FULL" pill.
    private var paymentStatus: some View {
        HStack(spacing: Spacing.xSmall) {
            if let paidViaText {
                Image(systemName: Layout.cardIcon)
                    .font(.system(size: Layout.cardIconSize))
                    .foregroundStyle(AlmatarColors.iconPrimaryStatic)
                    .accessibilityHidden(true)
                Text(paidViaText)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: Spacing.small)

            if let paidStatusTitle {
                Text(paidStatusTitle.uppercased())
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.medium))
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.xxxSmall)
                    .background(AlmatarColors.surfaceSuccessDark)
                    .clipShape(Capsule())
            }
        }
        .padding(Spacing.small)
        .background(AlmatarColors.surfaceCardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }

}
