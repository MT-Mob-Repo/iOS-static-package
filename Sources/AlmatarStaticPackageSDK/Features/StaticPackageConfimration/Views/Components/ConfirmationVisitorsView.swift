//
//  ConfirmationVisitorsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Names of the booked visitors, the main visitor first.
struct ConfirmationVisitorsView: View {
    private enum Layout {
        static let icon = "person"
    }

    let title: String
    let mainVisitorTitle: String
    let verifiedTitle: String
    let visitors: [CartTraveller]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            ConfirmationSectionTitle(title: title, icon: Layout.icon)

            VStack(spacing: Spacing.small) {
                ForEach(visitors, id: \.self) { visitorRow($0) }
            }
        }
        .confirmationCard()
    }

    private func visitorRow(_ visitor: CartTraveller) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Text(visitor.fullName)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(1)

            if visitor.isMainGuest {
                Text(mainVisitorTitle)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .lineLimit(1)
            }

            Spacer(minLength: Spacing.small)

            if visitor.isVerified == true {
                ConfirmationSuccessBadge(title: verifiedTitle, showsCheckmark: true)
            }
        }
    }
}
