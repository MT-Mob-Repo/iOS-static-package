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
        static let chevronDownIcon = "chevron.down"
        static let chevronUpIcon = "chevron.up"
    }

    @ObservedObject var form: VisitorDetailsFormModel
    let label: (_ visitorCount: Int) -> String
    let amount: String
    /// Optional second line under the label, e.g. "+ 1,680 SAR • Cabin upgrade".
    var detail: String? = nil
    /// Flips the chevron while the price breakdown is open.
    var isExpanded = false

    var body: some View {
        HStack(spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                Text(label(form.visitors.count))
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .lineLimit(1)

                if let detail {
                    SUITextPrice(text: detail, modifier: AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SUITextPrice(text: amount, modifier: AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            Image(systemName: isExpanded ? Layout.chevronUpIcon : Layout.chevronDownIcon)
                .font(.system(size: Layout.chevronSize, weight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.iconPrimaryStatic)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }

}
