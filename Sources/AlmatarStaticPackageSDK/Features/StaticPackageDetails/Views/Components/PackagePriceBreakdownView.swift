//
//  PackagePriceBreakdownView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// "Price Details": one card per breakdown section of the cart price.
/// Sections with items show a heading and one row per item; sections without items are totals
/// (e.g. "Total to pay") shown as a single bold row.
struct PackagePriceBreakdownView: View {
    private enum Layout {
        static let borderWidth: CGFloat = 1
    }

    let title: String
    let sections: [PriceBreakdownSection]
    /// Shown instead of an amount of zero, e.g. "Included".
    let includedTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            ForEach(sections.indices, id: \.self) { index in
                sectionView(sections[index])
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sections

    @ViewBuilder
    private func sectionView(_ section: PriceBreakdownSection) -> some View {
        if let items = section.items, !items.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(section.title)
                    .modifier(AppTextModifier(size: 14, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)

                card {
                    ForEach(items.indices, id: \.self) { index in
                        if index > 0 { divider }
                        itemRow(items[index])
                    }
                }
            }
        } else {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(section.title)
                    .modifier(AppTextModifier(size: 14, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)

                card { totalRow(section) }
            }
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            content()
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

    private var divider: some View {
        Rectangle()
            .fill(AlmatarColors.borderDefaultCard)
            .frame(height: Layout.borderWidth)
    }

    // MARK: - Rows

    private func itemRow(_ item: PriceBreakdownItem) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(item.label)
                    .modifier(AppTextModifier(size: 14, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .fixedSize(horizontal: false, vertical: true)

                if let description = item.description.nonEmpty {
                    Text(description)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            amountView(item.amount, size: Typography.Size.regular)
        }
    }

    private func totalRow(_ section: PriceBreakdownSection) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(section.title)
                    .modifier(AppTextModifier(size: 14, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)

                if let note = section.note.nonEmpty {
                    Text(note)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let amount = section.amount {
                amountView(amount, size: Typography.Size.medium)
            }
        }
    }

    @ViewBuilder
    private func amountView(_ amount: Double, size: CGFloat) -> some View {
        if amount == .zero {
            Text(includedTitle)
                .modifier(AppTextModifier(size: size, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
        } else {
            let price = CurrencyManager.shared.formatPrice(value: amount)
            SUITextPrice(
                text: price,
                modifier: AppTextModifier(size: size, fontWeight: Typography.Weight.medium)
            )
            .foregroundStyle(AlmatarColors.textPrimaryStatic)
            .lineLimit(1)
            .fixedSize()
        }
    }
}
