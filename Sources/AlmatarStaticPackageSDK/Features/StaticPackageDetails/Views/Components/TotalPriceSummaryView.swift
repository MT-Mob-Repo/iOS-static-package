//
//  TotalPriceSummaryView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// "Total price • 2 visitors" with the amount, shown above the payment button.
/// Observes the visitors form so the count updates as visitors are added or removed.
struct TotalPriceSummaryView: View {
    private enum Layout {
        static let currencyIconSize: CGFloat = 18
        static let chevronSize: CGFloat = 14
        static let chevronIcon = "chevron.down"
    }

    @ObservedObject var form: VisitorDetailsFormModel
    let label: (_ visitorCount: Int) -> String
    let amount: String

    var body: some View {
        HStack(spacing: Spacing.small) {
            Text(label(form.visitors.count))
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)

            SUITextPrice(text: amount, modifier: AppTextModifier(size: Typography.Size.xSemiLarge, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            Image(systemName: Layout.chevronIcon)
                .font(.system(size: Layout.chevronSize, weight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.iconPrimaryStatic)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

}
