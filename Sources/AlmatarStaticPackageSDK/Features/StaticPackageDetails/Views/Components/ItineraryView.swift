//
//  ItineraryView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Section title and subtitle, followed by one collapsible card per day.
struct ItineraryView: View {
    private enum Layout {
        static let imageHeight: CGFloat = 144
        static let descriptionLineLimit = 4
        static let chevronSize: CGFloat = 14
        static let actionIconSize: CGFloat = 14
        static let borderWidth: CGFloat = 1
        static let sectionLabelKerning: CGFloat = 1
        static let chevronUpIcon = "chevron.up"
        static let chevronDownIcon = "chevron.down"
        static let addIcon = "plus"
        static let addedIcon = "checkmark"
        static let downloadIcon = "square.and.arrow.down"
    }

    let strings: ItineraryStrings
    let days: [ItineraryDay]
    /// PDF version of the itinerary; hides the download button when `nil`.
    let downloadURL: URL?
    let activitySubtitle: (ItineraryActivity) -> String
    let isActivityAdded: (ItineraryActivity) -> Bool
    let onToggleActivity: (ItineraryActivity) -> Void

    /// The first day starts expanded.
    @State private var expandedDays: Set<Int>
    @Environment(\.layoutDirection) private var layoutDirection

    init(
        strings: ItineraryStrings,
        days: [ItineraryDay],
        downloadURL: URL? = nil,
        activitySubtitle: @escaping (ItineraryActivity) -> String,
        isActivityAdded: @escaping (ItineraryActivity) -> Bool,
        onToggleActivity: @escaping (ItineraryActivity) -> Void
    ) {
        self.strings = strings
        self.days = days
        self.downloadURL = downloadURL
        self.activitySubtitle = activitySubtitle
        self.isActivityAdded = isActivityAdded
        self.onToggleActivity = onToggleActivity
        _expandedDays = State(initialValue: Set(days.prefix(1).map(\.id)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            header

            VStack(spacing: Spacing.small) {
                ForEach(days) { dayCard($0) }
            }

            if let downloadURL {
                downloadButton(downloadURL)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(strings.title)
                .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            Text(strings.subtitle)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Day card

    private func dayCard(_ day: ItineraryDay) -> some View {
        let isExpanded = expandedDays.contains(day.id)

        return VStack(alignment: .leading, spacing: Spacing.medium) {
            dayHeader(day, isExpanded: isExpanded)

            if isExpanded {
                dayContent(day)
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

    private func dayHeader(_ day: ItineraryDay, isExpanded: Bool) -> some View {
        Button {
            withAnimation(.easeInOut) { toggle(day) }
        } label: {
            HStack(spacing: Spacing.small) {
                Text(strings.dayLabel(day.day))
                    .modifier(AppTextModifier(size: Typography.Size.xSmall, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textHighlightStatic)
                    .padding(.vertical, Spacing.xxSmall)
                    .frame(width: 60)
                    .background(AlmatarColors.surfaceSecondaryBase)
                    .clipShape(Capsule())

                Text(day.title)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: isExpanded ? Layout.chevronUpIcon : Layout.chevronDownIcon)
                    .font(.system(size: Layout.chevronSize, weight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.iconPrimaryStatic)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func dayContent(_ day: ItineraryDay) -> some View {
        if let url = day.image.nonEmpty.flatMap(URL.init(string:)) {
            dayImage(url)
        }

        if let description = day.description.nonEmpty {
            ExpandableTextView(
                text: description,
                collapsedLineLimit: Layout.descriptionLineLimit,
                readMoreTitle: strings.readMore,
                readLessTitle: strings.readLess,
                actionColor: AlmatarColors.textPrimaryInteractive
            )
        }
    }

    private func dayImage(_ url: URL) -> some View {
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
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .accessibilityHidden(true)
    }

    // MARK: - Activity

    private func activityRow(_ activity: ItineraryActivity) -> some View {
        HStack(spacing: Spacing.small) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(activity.name)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .fixedSize(horizontal: false, vertical: true)

                Text(activitySubtitle(activity))
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if activity.isOptional {
                addButton(activity)
            } else {
                includedPill
            }
        }
        .padding(Spacing.medium)
        .background(AlmatarColors.surfaceCardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    private var includedPill: some View {
        Text(strings.included)
            .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
            .foregroundStyle(AlmatarColors.textPrimaryStatic)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .overlay(
                Capsule().stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
            )
    }

    private func addButton(_ activity: ItineraryActivity) -> some View {
        let isAdded = isActivityAdded(activity)

        return Button {
            onToggleActivity(activity)
        } label: {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: isAdded ? Layout.addedIcon : Layout.addIcon)
                    .font(.system(size: Layout.actionIconSize, weight: Typography.Weight.semibold))
                Text(isAdded ? strings.added : strings.add)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
            }
            .foregroundStyle(AlmatarColors.textPrimaryInteractive)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(isAdded ? AlmatarColors.surfaceSecondaryHover : AlmatarColors.surfaceSecondaryBase)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Download

    /// Pill under the days that opens the itinerary PDF; title first, icon trailing.
    private func downloadButton(_ url: URL) -> some View {
        Link(destination: url) {
            HStack(spacing: Spacing.xSmall) {
                Text(strings.download)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.medium))
                Image(systemName: Layout.downloadIcon)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.light))
            }
            .foregroundStyle(AlmatarColors.textPrimaryInteractive)
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.xSmall)
            .background(AlmatarColors.surfaceSecondaryBase)
            .clipShape(Capsule())
        }
        .padding(.top, Spacing.small)
    }

    private func toggle(_ day: ItineraryDay) {
        if expandedDays.contains(day.id) {
            expandedDays.remove(day.id)
        } else {
            expandedDays.insert(day.id)
        }
    }
}

/// Localized text used by `ItineraryView`.
struct ItineraryStrings {
    let title: String
    let subtitle: String
    let activities: String
    let included: String
    let add: String
    let added: String
    let download: String
    let readMore: String
    let readLess: String
    let dayLabel: (Int) -> String
}

#Preview {
    ScrollView {
        ItineraryView(
            strings: ItineraryStrings(
                title: "Itinerary",
                subtitle: "Your step-by-step guide to an unforgettable trip",
                activities: "ACTIVITIES",
                included: "Included",
                add: "Add",
                added: "Added",
                download: "Download Itinerary",
                readMore: "Read more",
                readLess: "Read less",
                dayLabel: { "DAY \($0)" }
            ),
            days: ItineraryDay.mockItems,
            downloadURL: URL(string: "https://cdn.almatar.com/packages/six-flags-qiddiya/itinerary.pdf"),
            activitySubtitle: { $0.duration ?? "" },
            isActivityAdded: { _ in false },
            onToggleActivity: { _ in }
        )
        .padding(Spacing.screenHorizontal)
    }
}
