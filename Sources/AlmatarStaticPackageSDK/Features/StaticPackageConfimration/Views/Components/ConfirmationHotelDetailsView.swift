//
//  ConfirmationHotelDetailsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// A booked hotel, ready for display.
struct ConfirmationHotel: Identifiable, Hashable {
    let id: Int
    let imageURL: URL?
    let name: String
    /// e.g. "Riyadh, Saudi Arabia".
    let location: String?
    /// 0...5; no stars are shown for 0.
    let stars: Int
    let checkIn: String?
    let checkOut: String?
    let roomType: String?
    let boardBasis: String?
    let amenities: [JourneySnapshotItem]
}

/// Hotel photo, name, rating, stay dates, room and the amenities included.
struct ConfirmationHotelDetailsView: View {
    private enum Layout {
        static let icon = "building.2"
        static let imageHeight: CGFloat = 160
        static let starIcon = "star.fill"
        static let starSize: CGFloat = 12
        static let starTint = AlmatarColors.iconComplementaryYellow
        static let amenityIconSize: CGFloat = 14
        static let borderWidth: CGFloat = 1
    }

    struct Strings {
        let title: String
        let checkIn: String
        let checkOut: String
        let roomType: String
        let boardBasis: String
        let whatsIncluded: String
    }

    let strings: Strings
    let hotel: ConfirmationHotel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            ConfirmationSectionTitle(title: strings.title, icon: Layout.icon)

            if let url = hotel.imageURL {
                image(url)
            }

            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(hotel.name)
                    .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .fixedSize(horizontal: false, vertical: true)
                if let location = hotel.location {
                    Text(location)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                }
                if hotel.stars > 0 {
                    stars
                }
            }

            infoGrid(
                (strings.checkIn, hotel.checkIn),
                (strings.checkOut, hotel.checkOut)
            )
            ConfirmationDivider()
            infoGrid(
                (strings.roomType, hotel.roomType),
                (strings.boardBasis, hotel.boardBasis)
            )

            if !hotel.amenities.isEmpty {
                ConfirmationDivider()
                amenities
            }
        }
        .confirmationCard()
    }

    private func image(_ url: URL) -> some View {
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

    private var stars: some View {
        HStack(spacing: Spacing.xxxSmall) {
            ForEach(0..<hotel.stars, id: \.self) { _ in
                Image(systemName: Layout.starIcon)
                    .font(.system(size: Layout.starSize))
                    .foregroundStyle(Layout.starTint)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(hotel.stars)★")
    }

    /// Two label / value columns; hidden when both values are missing.
    @ViewBuilder
    private func infoGrid(_ leading: (String, String?), _ trailing: (String, String?)) -> some View {
        if leading.1 != nil || trailing.1 != nil {
            HStack(alignment: .top, spacing: Spacing.medium) {
                if let value = leading.1 {
                    ConfirmationLabeledValue(label: leading.0, value: value)
                } else {
                    Spacer().frame(maxWidth: .infinity)
                }
                if let value = trailing.1 {
                    ConfirmationLabeledValue(label: trailing.0, value: value)
                } else {
                    Spacer().frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var amenities: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(strings.whatsIncluded)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xSmall) {
                    ForEach(hotel.amenities) { amenityChip($0) }
                }
            }
        }
    }

    private func amenityChip(_ item: JourneySnapshotItem) -> some View {
        HStack(spacing: Spacing.xxSmall) {
            RemoteIconView(icon: item.iconName, size: Layout.amenityIconSize, tint: AlmatarColors.iconPrimaryStatic)
            Text(item.label)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.xSmall)
        .overlay(
            Capsule()
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
        )
    }
}
