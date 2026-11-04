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
        /// Hollow ring marking a layover on the flight path.
        static let stopMarkerSize: CGFloat = 8
        static let stopMarkerBorderWidth: CGFloat = 1.5
        static let pathLineHeight: CGFloat = 1
        static let titleDotSize: CGFloat = 4
        static let titleSeparator = " · "
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
                routeTitle(leg.route)
                if let subtitle = leg.subtitle.nonEmpty {
                    Text(subtitle)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                }
            }

            HStack(alignment: .top, spacing: Spacing.small) {
                endpoint(time: leg.departureTime, location: leg.departureLocation, alignment: .leading)
                path(leg.durationInfo, stopCodes: leg.stopCodes)
                endpoint(time: leg.arrivalTime, location: leg.arrivalLocation, alignment: .trailing)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// "Departure • Thu 16 Jul 2026" with a small gray dot between the parts.
    private func routeTitle(_ route: String) -> some View {
        let parts = route.components(separatedBy: Layout.titleSeparator)
        return HStack(spacing: Spacing.xSmall) {
            ForEach(Array(parts.enumerated()), id: \.offset) { index, part in
                if index > 0 {
                    Circle()
                        .fill(AlmatarColors.iconOnSurfacePrimaryDisabled)
                        .frame(width: Layout.titleDotSize, height: Layout.titleDotSize)
                }
                Text(part)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(parts.joined(separator: ", "))
    }

    private func endpoint(time: String?, location: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: Spacing.xxSmall) {
            if let time {
                Text(time)
                    .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }
            Text(location)
                .modifier(AppTextModifier(size: Typography.Size.small))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
                .lineLimit(Layout.locationLineLimit)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
    }

    /// "1h 45m • 1 stop" above a dot – line – dot route, with a ring and its airport code for each stop.
    private func path(_ durationInfo: String?, stopCodes: [String]) -> some View {
        VStack(spacing: Spacing.xSmall) {
            if let durationInfo {
                Text(durationInfo)
                    .modifier(AppTextModifier(size: Typography.Size.xSmall, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .multilineTextAlignment(.center)
                    .lineLimit(Layout.locationLineLimit)
                    .minimumScaleFactor(0.8)
            }
            HStack(alignment: .top, spacing: Spacing.xxxSmall) {
                pathDot
                ForEach(stopCodes.indices, id: \.self) { index in
                    pathLine
                    stopMarker(stopCodes[index])
                }
                pathLine
                pathDot
            }
        }
        .padding(.top, Spacing.xxSmall)
        .frame(width: Layout.pathWidth)
    }

    /// Centred on the stop markers' row so the line stays straight with or without stops.
    private var pathDot: some View {
        Circle()
            .fill(AlmatarColors.iconOnSurfacePrimaryDisabled)
            .frame(width: Layout.pathDotSize, height: Layout.pathDotSize)
            .frame(height: Layout.stopMarkerSize)
    }

    private var pathLine: some View {
        Rectangle()
            .fill(AlmatarColors.borderDefaultCard)
            .frame(height: Layout.pathLineHeight)
            .frame(maxWidth: .infinity)
            .frame(height: Layout.stopMarkerSize)
    }

    private func stopMarker(_ code: String) -> some View {
        VStack(spacing: Spacing.xxSmall) {
            Circle()
                .strokeBorder(AlmatarColors.textPrimaryInteractive, lineWidth: Layout.stopMarkerBorderWidth)
                .background(Circle().fill(AlmatarColors.surfaceCard))
                .frame(width: Layout.stopMarkerSize, height: Layout.stopMarkerSize)
            Text(code)
                .modifier(AppTextModifier(size: Typography.Size.xSmall, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .lineLimit(1)
                .fixedSize()
        }
        .frame(width: Layout.stopMarkerSize)
    }
}

