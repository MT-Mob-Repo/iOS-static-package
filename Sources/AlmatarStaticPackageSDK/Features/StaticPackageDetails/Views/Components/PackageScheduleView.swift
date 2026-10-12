//
//  PackageScheduleView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Section title followed by a vertical timeline of schedule steps.
/// Each step shows its title, an expandable description, an optional tag / status row
/// and an optional detail card (with or without image, rating, details, description and room).
struct PackageScheduleView: View {
    private enum Layout {
        static let markerSize: CGFloat = 16
        static let markerDotSize: CGFloat = 6
        static let markerBorderWidth: CGFloat = 1.5
        /// Aligns the marker with the first line of the step title.
        static let markerTopInset: CGFloat = 2
        static let connectorDotSize: CGFloat = 5
        static let connectorDotSpacing: CGFloat = 16
        static let descriptionLineLimit = 3
        static let imageHeight: CGFloat = 120
        static let smallIconSize: CGFloat = 14
        static let ratingIconSize: CGFloat = 12
        static let borderWidth: CGFloat = 1
        static let titleLineLimit = 2
        static let ratingFractionDigits = 1
        // TODO: Replace with the design-system success color once available.
        static let ratingTint = AlmatarColors.iconComplementaryGreen
        static let ratingBackgroundOpacity: Double = 0.1
    }

    let title: String
    let subTitle: String
    let items: [PackageScheduleItem]
    let readMoreTitle = LocalizedKey.readMore.localized()
    let readLessTitle = LocalizedKey.readLess.localized()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            Text(subTitle)
                .modifier(AppTextModifier(size: Typography.Size.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
            
            VStack(alignment: .leading, spacing: Spacing.zero) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    stepRow(item, isLast: index == items.count - 1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Timeline

    private func stepRow(_ item: PackageScheduleItem, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            VStack(spacing: Spacing.xSmall) {
                marker
                // The last step has nothing to connect to.
                if !isLast {
                    connector.frame(maxHeight: .infinity)
                }
            }
            .frame(width: Layout.markerSize)
            .padding(.top, Layout.markerTopInset)

            stepContent(item)
                .padding(.bottom, isLast ? Spacing.zero : Spacing.medium)
        }
        // Lets the connector stretch down to the next step.
        .fixedSize(horizontal: false, vertical: true)
    }

    private var marker: some View {
        Circle()
            .stroke(AlmatarColors.textPrimaryStatic, lineWidth: Layout.markerBorderWidth)
            .frame(width: Layout.markerSize, height: Layout.markerSize)
            .overlay(
                Circle()
                    .fill(AlmatarColors.textPrimaryStatic)
                    .frame(width: Layout.markerDotSize, height: Layout.markerDotSize)
            )
            .accessibilityHidden(true)
    }

    private var connector: some View {
        VerticalLine()
            .stroke(
                AlmatarColors.borderDefaultCard,
                style: StrokeStyle(lineWidth: Layout.connectorDotSize, lineCap: .round, dash: [0, Layout.connectorDotSpacing])
            )
            .frame(width: Layout.connectorDotSize)
            .accessibilityHidden(true)
    }

    // MARK: - Step

    private func stepContent(_ item: PackageScheduleItem) -> some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(item.title)
                    .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .fixedSize(horizontal: false, vertical: true)

                if let description = item.description.nonEmpty {
                    ExpandableTextView(
                        text: description,
                        collapsedLineLimit: Layout.descriptionLineLimit,
                        readMoreTitle: readMoreTitle,
                        readLessTitle: readLessTitle
                    )
                }
            }

            if item.tag != nil || item.statusLabel.nonEmpty != nil {
                tagRow(tag: item.tag, status: item.statusLabel.nonEmpty)
            }

            if let card = item.card {
                cardView(card)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Tag at the leading edge, status at the trailing edge; either may be missing.
    private func tagRow(tag: PackageScheduleTag?, status: String?) -> some View {
        HStack(spacing: Spacing.small) {
            if let tag {
                tagChip(tag)
            }
            Spacer(minLength: Spacing.zero)
            if let status {
                statusPill(status)
            }
        }
    }

    // MARK: - Card

    private func cardView(_ card: PackageScheduleCard) -> some View {
        let imageURL = card.imageUrl.nonEmpty.flatMap(URL.init(string:))
        let description = card.description.nonEmpty
        let details = card.details ?? []
        let status = card.statusLabel.nonEmpty
        // Image cards with a description use a lighter title and separate the footer with a divider.
        let isMediaCard = imageURL != nil && description != nil
        let hasFooter = card.room != nil || status != nil

        return VStack(alignment: .leading, spacing: Spacing.small) {
            if let imageURL {
                cardImage(imageURL)
            }

            cardHeader(card, isMediaCard: isMediaCard)

            if !details.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    ForEach(details, id: \.self) { infoRow($0) }
                }
            }

            if let description {
                Text(description)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if hasFooter {
                Rectangle()
                    .fill(AlmatarColors.borderDefaultCard)
                    .frame(height: Layout.borderWidth)
                cardFooter(room: card.room, status: status)
            }
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

    private func cardImage(_ url: URL) -> some View {
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
                        // Loading and failure share the same placeholder.
                        AlmatarColors.surfaceCardSecondary
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
            .accessibilityHidden(true)
    }

    private func cardHeader(_ card: PackageScheduleCard, isMediaCard: Bool) -> some View {
        HStack(alignment: .top, spacing: Spacing.small) {
            Text(card.title)
                .modifier(AppTextModifier(
                    size: isMediaCard ? Typography.Size.medium : Typography.Size.large,
                    fontWeight: isMediaCard ? Typography.Weight.semibold : Typography.Weight.medium
                ))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(Layout.titleLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if let rating = card.rating {
                ratingBadge(rating)
            }
        }
    }

    private func ratingBadge(_ rating: Double) -> some View {
        HStack(spacing: Spacing.xxSmall) {
            RemoteIconView(icon: "star.fill", size: Layout.ratingIconSize, tint: Layout.ratingTint)
            Text(rating.formatted(.number.precision(.fractionLength(Layout.ratingFractionDigits))))
                .modifier(AppTextModifier(size: Typography.Size.regular))
                .foregroundStyle(Layout.ratingTint)
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.xSmall)
        .background(Layout.ratingTint.opacity(Layout.ratingBackgroundOpacity))
        .clipShape(Capsule())
    }

    private func infoRow(_ info: PackageScheduleInfo) -> some View {
        HStack(spacing: Spacing.xSmall) {
            RemoteIconView(icon: info.icon, size: Layout.smallIconSize, tint: AlmatarColors.textSecondaryStatic)
            Text(info.text)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
        }
    }

    /// Room details at the leading edge and the status pill at the trailing edge;
    /// the pill stays leading when there is no room.
    private func cardFooter(room: PackageScheduleRoom?, status: String?) -> some View {
        HStack(spacing: Spacing.small) {
            if let room {
                VStack(alignment: .leading, spacing: Spacing.xSmall) {
                    Text(room.title)
                        .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    if let subtitle = room.subtitle.nonEmpty {
                        Text(subtitle)
                            .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                            .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    }
                }
                Spacer(minLength: Spacing.small)
            }
            if let status {
                statusPill(status, isRegular: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Badges

    private func tagChip(_ tag: PackageScheduleTag) -> some View {
        HStack(spacing: Spacing.xxSmall) {
            if let icon = tag.icon.nonEmpty {
                RemoteIconView(icon: icon, size: Layout.smallIconSize, tint: AlmatarColors.iconPrimaryStatic)
            }
            Text(tag.title)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.xSmall)
        .background(AlmatarColors.surfaceCardSecondary)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
        )
    }

    private func statusPill(_ title: String, isRegular: Bool = false) -> some View {
        Text(title)
            .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: isRegular ? Typography.Weight.regular : Typography.Weight.semibold))
            .foregroundStyle(AlmatarColors.textPrimaryStatic)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(AlmatarColors.surfaceCardSecondary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
            )
    }
}

/// A vertical line through the middle of its frame, used for the dotted timeline connector.
private struct VerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

private extension Optional where Wrapped == String {
    /// The string, or `nil` when it is missing or blank.
    var nonEmpty: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}
