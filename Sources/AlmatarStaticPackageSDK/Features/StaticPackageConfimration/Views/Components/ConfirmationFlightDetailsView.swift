//
//  ConfirmationFlightDetailsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Departure and return legs, each with times, airports and duration.
struct ConfirmationFlightDetailsView: View {
    private enum Layout {
        static let icon = "airplane"
        static let pathWidth: CGFloat = 90
        static let pathDotSize: CGFloat = 6
        static let locationLineLimit = 2
    }

    let title: String
    let legs: [PackageScheduleFlightLeg]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            ConfirmationSectionTitle(title: title, icon: Layout.icon)

            ForEach(Array(legs.enumerated()), id: \.offset) { index, leg in
                if index > 0 {
                    ConfirmationDivider()
                }
                legView(leg)
            }
        }
        .confirmationCard()
    }

    private func legView(_ leg: PackageScheduleFlightLeg) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(leg.route)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                if let subtitle = leg.subtitle.nonEmpty {
                    Text(subtitle)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                }
            }

            HStack(alignment: .top, spacing: Spacing.small) {
                endpoint(time: leg.departureTime, location: leg.departureLocation, alignment: .leading)
                path(leg.durationInfo)
                endpoint(time: leg.arrivalTime, location: leg.arrivalLocation, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func endpoint(time: String?, location: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: Spacing.xxSmall) {
            if let time {
                Text(time)
                    .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.bold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }
            Text(location)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                .lineLimit(Layout.locationLineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
    }

    /// "1h 45m • Direct" above a dot – line – dot route.
    private func path(_ durationInfo: String?) -> some View {
        VStack(spacing: Spacing.xSmall) {
            if let durationInfo {
                Text(durationInfo)
                    .modifier(AppTextModifier(size: Typography.Size.xSmall, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .multilineTextAlignment(.center)
                    .lineLimit(Layout.locationLineLimit)
                    .minimumScaleFactor(0.8)
            }
            HStack(spacing: Spacing.zero) {
                pathDot
                ConfirmationDivider()
                pathDot
            }
        }
        .padding(.top, Spacing.xxSmall)
        .frame(width: Layout.pathWidth)
    }

    private var pathDot: some View {
        Circle()
            .fill(AlmatarColors.iconOnSurfaceTertirary)
            .frame(width: Layout.pathDotSize, height: Layout.pathDotSize)
    }
}
