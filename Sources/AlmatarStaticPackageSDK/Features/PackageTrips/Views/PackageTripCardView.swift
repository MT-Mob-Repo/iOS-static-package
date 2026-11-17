//
//  PackageTripCardView.swift
//  AlmatarStaticPackageSDK
//
//  My Trips card for a Static Package booking: the booking header (title,
//  date range • travellers and status badge), then each included product
//  (flight / hotel / activity) as its own section.
//

import SwiftUI
import AlmatarSystemDesignSDK

/// The My Trips card for one package booking, for host apps that list package trips
/// next to their other bookings. Get it from `AlmatarStaticPackageSDK.getPackageTripCardView(trip:isPast:onTap:)`.
public struct PackageTripCardView: View {
    private enum Layout {
        static let borderWidth: CGFloat = 1
        static let badgeHeight: CGFloat = 20
        static let badgeBorderOpacity: Double = 0.4
    }

    private let model: PackageTripCardModel
    private let onTap: () -> Void

    @MainActor
    init(trip: PackageTrip, isPast: Bool, onTap: @escaping () -> Void) {
        self.model = PackageTripCardModel(trip: trip, isPast: isPast)
        self.onTap = onTap
    }

    public var body: some View {
        VStack(spacing: Spacing.smallMedium) {
            header

            ForEach(Array(model.products.enumerated()), id: \.element.id) { index, product in
                if index > 0 {
                    TripHorizontalDivider()
                }
                switch product {
                case .flight(let flight): PackageTripFlightSection(flight: flight)
                case .hotel(let hotel): PackageTripHotelSection(hotel: hotel)
                case .activity(let activity): PackageTripActivitySection(activity: activity)
                }
            }
        }
        .padding(Spacing.smallMedium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AlmatarColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xLarge)
                .inset(by: Layout.borderWidth / 2)
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                if !model.title.isEmpty {
                    Text(model.title)
                        .modifier(AppTextModifier(size: Typography.Size.xSemiLarge, fontWeight: Typography.Weight.medium))
                        .foregroundStyle(AlmatarColors.textPrimaryStatic)
                        .lineLimit(2)
                }
                if !model.subtitle.isEmpty {
                    Text(model.subtitle)
                        .modifier(AppTextModifier(size: Typography.Size.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            statusBadge
        }
    }

    private var statusBadge: some View {
        Text(model.badgeTitle.uppercased())
            .modifier(AppTextModifier(size: Typography.Size.xSmall, fontWeight: Typography.Weight.semibold))
            .foregroundStyle(badgeColor)
            .padding(.horizontal, Spacing.small)
            .frame(height: Layout.badgeHeight)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.small)
                    .inset(by: Layout.borderWidth / 2)
                    .stroke(badgeColor.opacity(Layout.badgeBorderOpacity), lineWidth: Layout.borderWidth)
            )
    }

    private var badgeColor: Color {
        switch model.badge {
        case .past: return AlmatarColors.textSecondaryStatic
        case .status(.confirmed): return AlmatarColors.textComplementaryGreen
        case .status(.partiallyConfirmed), .status(.pending): return AlmatarColors.textComplementaryYellow
        case .status(.failed), .status(.cancelled): return AlmatarColors.textComplementaryRed
        }
    }
}

// MARK: - Flight section

private struct PackageTripFlightSection: View {
    private enum Layout {
        static let logoSize: CGFloat = 24
        static let stopDotSize: CGFloat = 8
    }

    let flight: PackageTripCardModel.Flight

    @Environment(\.layoutDirection) private var layoutDirection

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            Text(flight.routeTitle)
                .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            if !flight.subtitle.isEmpty {
                Text(flight.subtitle)
                    .modifier(AppTextModifier(size: Typography.Size.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
            }

            ForEach(flight.legs) { leg in
                HStack(spacing: Spacing.small) {
                    TripRemoteImage(url: leg.logoURL, contentMode: .fit)
                        .frame(width: Layout.logoSize, height: Layout.logoSize)
                    TripVerticalDivider()
                    timeBlock(time: leg.departureTime, city: leg.departureCity)
                    infoBlock(leg)
                    timeBlock(time: leg.arrivalTime, city: leg.arrivalCity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func timeBlock(time: String, city: String) -> some View {
        VStack(spacing: Spacing.xxSmall) {
            Text(time)
                .modifier(AppTextModifier(size: Typography.Size.regular))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
            Text(city)
                .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textHighlightStatic)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private func infoBlock(_ leg: PackageTripCardModel.FlightLeg) -> some View {
        VStack(spacing: Spacing.xxSmall) {
            Text(leg.stopsTitle)
                .modifier(AppTextModifier(size: Typography.Size.xSmall))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            ZStack {
                Image(systemName: "arrow.right")
                    .font(.system(size: Typography.Size.small, weight: .regular))
                    .foregroundStyle(AlmatarColors.iconSecondaryStatic)
                    .scaleEffect(x: layoutDirection == .rightToLeft ? -1 : 1, y: 1)
                if leg.hasStops {
                    Circle()
                        .fill(AlmatarColors.iconComplementaryYellow)
                        .frame(width: Layout.stopDotSize, height: Layout.stopDotSize)
                }
            }

            if !leg.duration.isEmpty {
                Text(leg.duration)
                    .modifier(AppTextModifier(size: Typography.Size.xSmall))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Hotel section

private struct PackageTripHotelSection: View {
    private enum Layout {
        static let imageWidth: CGFloat = 67
        static let imageHeight: CGFloat = 83
        static let infoHeight: CGFloat = 104
    }

    let hotel: PackageTripCardModel.Hotel

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            if !hotel.title.isEmpty {
                Text(hotel.title)
                    .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }

            HStack(spacing: Spacing.small) {
                TripRemoteImage(url: hotel.imageURL, contentMode: .fill)
                    .frame(width: Layout.imageWidth, height: Layout.imageHeight)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))

                TripVerticalDivider()
                dateInfo(title: hotel.checkInTitle, date: hotel.checkIn)
                TripVerticalDivider()
                dateInfo(title: hotel.checkOutTitle, date: hotel.checkOut)
                TripVerticalDivider()
                roomInfo
            }
            .frame(height: Layout.infoHeight)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func dateInfo(title: String, date: Date?) -> some View {
        VStack(spacing: Spacing.xSmall) {
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.xSmall))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let date {
                Text(tripDateFormatter("dd").string(from: date))
                    .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textHighlightStatic)
                Text(tripDateFormatter("MMMM").string(from: date))
                    .modifier(AppTextModifier(size: Typography.Size.small))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                Text(tripDateFormatter("EEEE").string(from: date))
                    .modifier(AppTextModifier(size: Typography.Size.xSmall))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
            } else {
                Text("-")
                    .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textHighlightStatic)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var roomInfo: some View {
        VStack(spacing: Spacing.xSmall) {
            Text(hotel.roomsTitle)
                .modifier(AppTextModifier(size: Typography.Size.xSmall))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
            Text(String(hotel.roomsCount))
                .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textHighlightStatic)
            TripHorizontalDivider()
            Text(hotel.nightsTitle)
                .modifier(AppTextModifier(size: Typography.Size.xSmall))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
            Text(String(hotel.nightsCount))
                .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textHighlightStatic)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Activity / add-on section

private struct PackageTripActivitySection: View {
    private enum Layout {
        static let imageSize: CGFloat = 67
        static let lineLimit = 2
    }

    let activity: PackageTripCardModel.Activity

    var body: some View {
        HStack(spacing: Spacing.small) {
            if activity.imageURL != nil {
                TripRemoteImage(url: activity.imageURL, contentMode: .fill)
                    .frame(width: Layout.imageSize, height: Layout.imageSize)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.small))
            }

            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                if !activity.title.isEmpty {
                    Text(activity.title)
                        .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.medium))
                        .foregroundStyle(AlmatarColors.textPrimaryStatic)
                        .lineLimit(Layout.lineLimit)
                }
                if !activity.subtitle.isEmpty {
                    Text(activity.subtitle)
                        .modifier(AppTextModifier(size: Typography.Size.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                        .lineLimit(Layout.lineLimit)
                }
            }

            Spacer(minLength: Spacing.zero)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Shared pieces

private struct TripRemoteImage: View {
    let url: URL?
    let contentMode: ContentMode

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: contentMode)
            default:
                // Loading and failure share the same placeholder.
                AlmatarColors.surfaceCardSecondary
            }
        }
    }
}

private struct TripVerticalDivider: View {
    var body: some View {
        Rectangle()
            .fill(AlmatarColors.borderDefaultCard)
            .frame(width: 1)
    }
}

private struct TripHorizontalDivider: View {
    var body: some View {
        Rectangle()
            .fill(AlmatarColors.borderDefaultCard)
            .frame(height: 1)
    }
}
