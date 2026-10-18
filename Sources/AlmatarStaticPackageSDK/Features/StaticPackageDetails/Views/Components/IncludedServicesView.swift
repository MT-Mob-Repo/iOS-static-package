//
//  IncludedServicesView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Section title and subtitle, followed by the services included in the package.
struct IncludedServicesView: View {
    private enum Layout {
        static let iconSize: CGFloat = 24
        static let borderWidth: CGFloat = 1
    }

    let title: String
    let subtitle: String
    let includedTitle: String
    let items: [IncludedServiceItem]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            header

            Text(includedTitle)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .padding(.top, Spacing.small)

            VStack(spacing: Spacing.small) {
                ForEach(items) { card($0) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            Text(subtitle)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func card(_ item: IncludedServiceItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(spacing: Spacing.small) {
                RemoteIconView(icon: item.icon, size: Layout.iconSize, tint: AlmatarColors.iconPrimaryStatic)

                Text(item.title)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }

            if let description = item.description, !description.isEmpty {
                Text(description)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xLarge)
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
        )
    }
}

#Preview {
    IncludedServicesView(
        title: "Included Services",
        subtitle: "Confirm or customize your configuration below",
        includedTitle: "Included in Your Pass",
        items: IncludedServiceItem.mockItems
    )
    .padding(Spacing.screenHorizontal)
}
