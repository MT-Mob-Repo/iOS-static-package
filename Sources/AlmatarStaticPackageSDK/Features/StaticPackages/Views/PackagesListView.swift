//
//  PackagesListView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// A titled list of package cards provided by the host app.
/// "Book" creates a cart for the package, then pushes its details screen,
/// so the view must be inside a `NavigationStack`.
public struct PackagesListView: View {
    private enum Layout {
        static let imageHeight: CGFloat = 200
        static let titleLineLimit = 2
        static let borderWidth: CGFloat = 1
        static let ribbonIconSize: CGFloat = 14
        static let durationBackground = Color.black.opacity(0.8)
        static let onImageText = Color.white
        static let categoriesKerning: CGFloat = 0.5
    }

    @StateObject private var viewModel: PackagesListViewModel
    @Environment(\.layoutDirection) private var layoutDirection

    /// - Parameter section: The title and packages to show.
    public init(section: PackagesSection) {
        _viewModel = StateObject(wrappedValue: PackagesListViewModel(
            section: section,
            repository: AlmatarStaticPackageSDK.shared.makeStaticPackagesRepository()
        ))
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            if let title = viewModel.section.title.nonEmpty {
                Text(title)
                    .modifier(AppTextModifier(size: Typography.Size.xSemiLarge, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }

            VStack(spacing: Spacing.medium) {
                ForEach(viewModel.section.packages) { packageCard($0) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .navigationDestination(isPresented: isShowingDetails) {
            if let packageId = viewModel.bookedPackageId {
                AlmatarStaticPackageSDK.shared.getStaticPackageDetailsView(packageId: packageId)
            }
        }
        .alert(
            viewModel.bookingErrorMessage ?? "",
            isPresented: isShowingError
        ) {
            Button(viewModel.okTitle, role: .cancel) {}
        }
    }

    private var isShowingDetails: Binding<Bool> {
        Binding(
            get: { viewModel.bookedPackageId != nil },
            set: { if !$0 { viewModel.bookedPackageId = nil } }
        )
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.bookingErrorMessage != nil },
            set: { if !$0 { viewModel.bookingErrorMessage = nil } }
        )
    }

    // MARK: - Card

    private func packageCard(_ package: PackageSummary) -> some View {
        VStack(alignment: .leading, spacing: Spacing.zero) {
            cardImage(package)

            VStack(alignment: .leading, spacing: Spacing.small) {
                if let categories = viewModel.categoriesText(package) {
                    Text(categories)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                        // Letter spacing breaks Arabic letter joining, so it is applied to LTR only.
                        .kerning(layoutDirection == .rightToLeft ? .zero : Layout.categoriesKerning)
                        .foregroundStyle(AlmatarColors.textHighlightStatic)
                }

                Text(package.name)
                    .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .lineLimit(Layout.titleLineLimit)

                if let description = package.description.nonEmpty {
                    Text(description)
                        .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !package.tags.isEmpty {
                    FlowLayout(spacing: Spacing.xSmall) {
                        ForEach(package.tags, id: \.self) { tagChip($0) }
                    }
                }

                Rectangle()
                    .fill(AlmatarColors.borderDefaultCard)
                    .frame(height: Layout.borderWidth)
                    .padding(.vertical, Spacing.xxSmall)

                footer(package)
            }
            .padding(Spacing.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AlmatarColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xxxLarge))
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.xxxLarge)
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
        )
    }

    private func cardImage(_ package: PackageSummary) -> some View {
        // Fixed-size container so a filled image never widens the card.
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: Layout.imageHeight)
            .overlay(
                AsyncImage(url: viewModel.imageURL(package)) { phase in
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
            .clipped()
            .overlay(alignment: .top) { imageBadges(package) }
    }

    private func imageBadges(_ package: PackageSummary) -> some View {
        HStack(alignment: .top, spacing: Spacing.xSmall) {
            if let duration = package.duration.nonEmpty {
                Text(duration)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(Layout.onImageText)
                    .padding(.horizontal, Spacing.small)
                    .padding(.vertical, Spacing.xSmall)
                    .background(Layout.durationBackground)
                    .clipShape(Capsule())
            }

            Spacer(minLength: Spacing.zero)

            if let ribbon = package.ribbons.first {
                ribbonView(ribbon)
            }
        }
        .padding(Spacing.medium)
    }

    private func ribbonView(_ ribbon: PackageRibbon) -> some View {
        HStack(spacing: Spacing.xxSmall) {
            if let icon = ribbon.icon.nonEmpty {
                RemoteIconView(icon: icon, size: Layout.ribbonIconSize, tint: Layout.onImageText)
            }
            Text(ribbon.text.uppercased())
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.medium))
                .foregroundStyle(Layout.onImageText)
        }
        .padding(.horizontal, Spacing.small)
        .padding(.vertical, Spacing.xSmall)
        .background(ribbon.color.nonEmpty.map { Color($0) } ?? AlmatarColors.surfaceDangerDark)
        .clipShape(Capsule())
    }

    private func tagChip(_ tag: String) -> some View {
        Text(tag)
            .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
            .foregroundStyle(AlmatarColors.textPrimaryStatic)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xSmall)
            .background(AlmatarColors.surfaceCardSecondary)
            .clipShape(Capsule())
            .overlay(Capsule().stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth))
    }

    // MARK: - Footer

    private func footer(_ package: PackageSummary) -> some View {
        HStack(alignment: .center, spacing: Spacing.small) {
            if let price = viewModel.priceText(package) {
                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(viewModel.startingFromTitle)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)

                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xxSmall) {
                        Text(price)
                            .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.semibold))
                            .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    }
                }
            }

            Spacer(minLength: Spacing.zero)

            AppButton(
                viewModel.bookTitle,
                style: .primary,
                size: .small,
                isLoading: viewModel.isBooking(package),
                isDisabled: viewModel.isBooking && !viewModel.isBooking(package)
            ) {
                Task { await viewModel.bookTapped(package) }
            }
        }
    }
}

/// Lays children out in rows, wrapping to the next row when one is full.
private struct FlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let neededWidth = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if neededWidth > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            current.height = max(current.height, size.height)
            current.indices.append(index)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            PackagesListView(section: .mock)
                .padding(Spacing.screenHorizontal)
        }
    }
}
