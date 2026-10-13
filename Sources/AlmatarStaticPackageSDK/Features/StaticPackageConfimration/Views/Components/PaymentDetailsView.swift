//
//  PaymentDetailsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// A priced line in the payment breakdown.
struct PaymentDetailsLine: Hashable {
    let title: String
    let subtitle: String?
    /// Shown as "× n" when more than one unit was booked.
    let quantity: Int?
    /// Already formatted, e.g. "SAR 450".
    let amount: String
}

/// Priced lines followed by the total paid.
struct PaymentDetailsView: View {
    private enum Layout {
        static let borderWidth: CGFloat = 1
        static let quantityPrefix = "× "
    }

    let title: String
    let lines: [PaymentDetailsLine]
    let totalTitle: String
    let total: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            ConfirmationSectionTitle(title: title)

            if !lines.isEmpty {
                VStack(spacing: Spacing.small) {
                    ForEach(lines, id: \.self) { lineView($0) }
                }

                Rectangle()
                    .fill(AlmatarColors.borderDefaultCard)
                    .frame(height: Layout.borderWidth)
            }

            HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
                Text(totalTitle)
                    .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)

                Spacer(minLength: Spacing.small)

                Text(total)
                    .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }
        }
        .confirmationCard()
    }

    private func lineView(_ line: PaymentDetailsLine) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(lineTitle(line))
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .fixedSize(horizontal: false, vertical: true)

                if let subtitle = line.subtitle {
                    Text(subtitle)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: Spacing.small)

            Text(line.amount)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
        }
    }

    private func lineTitle(_ line: PaymentDetailsLine) -> String {
        guard let quantity = line.quantity else { return line.title }
        return "\(line.title) \(Layout.quantityPrefix)\(quantity)"
    }
}

#Preview {
    PaymentDetailsView(
        title: "Payment Details",
        lines: [
            PaymentDetailsLine(title: "Private airport transfer", subtitle: "Jeddah to Makkah, one way", quantity: nil, amount: "SAR 450")
        ],
        totalTitle: "Total Paid",
        total: "SAR 2,900"
    )
    .padding(Spacing.screenHorizontal)
}
