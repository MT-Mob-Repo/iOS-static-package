//
//  PackageDetailsHeaderView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import UIKit
import AlmatarSystemDesignSDK

/// Full-bleed image carousel with an expandable summary card that overlays the header.
struct PackageDetailsHeaderView: View {
    private enum Layout {
        static let headerHeight: CGFloat = 420
        /// How far the card sits up over the carousel image.
        static let cardOverlap: CGFloat = 64
        static let cardHorizontalInset: CGFloat = 16
        static let cardCornerRadius: CGFloat = CornerRadius.xxxLarge
        static let borderWidth: CGFloat = 1
        static let pageDotSize: CGFloat = 7
        static let pageDotSpacing: CGFloat = 6
        static let pageDotsBottomPadding: CGFloat = 12
        static let shadowColor = Color(red: 24 / 255, green: 39 / 255, blue: 75 / 255).opacity(0.12)
    }

    let title: String
    let description: String?
    let tags: [String]
    let metaLine: String?
    /// Asset catalog names from `Assets.xcassets` (loaded via `Bundle.module`).
    let imageNames: [String]

    @State private var currentPage = 0
    @State private var isExpanded = false

    private var slides: [String] {
        imageNames.isEmpty ? PackageAsset.carouselImageNames : imageNames
    }

    private var slideCount: Int {
        max(slides.count, 1)
    }

    var body: some View {
        // Carousel layout height is shortened so the card can sit in the remaining
        // space while the image still paints underneath (overlay). Avoids TabView
        // inside ScrollView covering the card.
        VStack(spacing: 0) {
            Color.clear
                .frame(height: Layout.headerHeight - Layout.cardOverlap)
                .overlay(alignment: .top) {
                    carousel
                        .frame(height: Layout.headerHeight)
                        .frame(maxWidth: .infinity)
                }
                .overlay(alignment: .bottom) {
                    pageDots
                        .padding(.bottom, Layout.pageDotsBottomPadding)
                }

            summaryCard
                .padding(.horizontal, Layout.cardHorizontalInset)
        }
    }

    // MARK: - Carousel

    private var carousel: some View {
        GeometryReader { proxy in
            TabView(selection: $currentPage) {
                ForEach(0..<slideCount, id: \.self) { index in
                    slide(at: index)
                        .frame(width: proxy.size.width, height: Layout.headerHeight)
                        .clipped()
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .frame(height: Layout.headerHeight)
        .clipped()
    }

    @ViewBuilder
    private func slide(at index: Int) -> some View {
        let name = slides[index % slides.count]
        if UIImage(named: name, in: .module, compatibleWith: nil) != nil {
            Image(name, bundle: .module)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
        } else {
            placeholder(at: index, assetName: name)
        }
    }

    private func placeholder(at index: Int, assetName: String) -> some View {
        let hues: [Color] = [
            Color(red: 0.55, green: 0.62, blue: 0.72),
            Color(red: 0.45, green: 0.52, blue: 0.62),
            Color(red: 0.62, green: 0.58, blue: 0.52),
            Color(red: 0.50, green: 0.56, blue: 0.48)
        ]
        return hues[index % hues.count]
            .overlay {
                VStack(spacing: Spacing.xSmall) {
                    Image(systemName: "photo")
                        .font(.system(size: 36, weight: .light))
                    Text(assetName)
                        .modifier(AppTextModifier(size: Typography.Size.xSmall, fontWeight: Typography.Weight.medium))
                }
                .foregroundStyle(.white.opacity(0.7))
            }
    }

    // MARK: - Page dots (round)

    private var pageDots: some View {
        HStack(spacing: Layout.pageDotSpacing) {
            ForEach(0..<slideCount, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.white : Color.white.opacity(0.45))
                    .frame(width: Layout.pageDotSize, height: Layout.pageDotSize)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(currentPage + 1) of \(slideCount)"))
    }

    // MARK: - Expandable summary card

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: Spacing.small) {
            HStack(alignment: .center, spacing: Spacing.xSmall) {
                tagsRow
                Spacer(minLength: Spacing.xSmall)
                expandToggle
            }

            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.xLarge, fontWeight: Typography.Weight.bold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .fixedSize(horizontal: false, vertical: true)

            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(Spacing.medium)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AlmatarColors.surfaceCard)
        .clipShape(RoundedRectangle(cornerRadius: Layout.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Layout.cardCornerRadius)
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
        )
        .shadow(color: Layout.shadowColor, radius: 5, x: 0, y: 2)
        .shadow(color: Layout.shadowColor, radius: 10, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
    }

    private var tagsRow: some View {
        HStack(spacing: Spacing.xSmall) {
            ForEach(tags, id: \.self) { tag in
                Text(tag)
                    .modifier(AppTextModifier(size: Typography.Size.xSmall, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .padding(.horizontal, Spacing.xSmall)
                    .padding(.vertical, Spacing.xxSmall)
                    .background(AlmatarColors.surfaceCard)
                    .overlay(
                        Capsule()
                            .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
                    )
                    .clipShape(Capsule())
            }
        }
    }

    private var expandToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
            }
        } label: {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .frame(width: 28, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isExpanded ? "Collapse" : "Expand"))
    }

    @ViewBuilder
    private var expandedContent: some View {
        if let description, !description.isEmpty {
            Text(description)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .fixedSize(horizontal: false, vertical: true)
        }

        if let metaLine, !metaLine.isEmpty {
            Text(metaLine)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
        }
    }
}

#Preview("Collapsed") {
    ScrollView {
        PackageDetailsHeaderView(
            title: "Six Flags Qiddiya City",
            description: "Our exclusive 7-night Al-Safwa Premium Umrah package marries physical comfort with deep spiritual focus in Makkah & Madinah.",
            tags: ["Dynamic Package", "7 Nights"],
            metaLine: "7 Nights • Private Escort",
            imageNames: PackageAsset.carouselImageNames
        )
    }
}

#Preview("Expanded") {
    ScrollView {
        PackageDetailsHeaderView(
            title: "Falcon’s Adventure",
            description: "Our exclusive 7-night Al-Safwa Premium Umrah package marries physical comfort with deep spiritual focus in Makkah & Madinah.",
            tags: ["DYNAMIC PACKAGE", "7 NIGHTS"],
            metaLine: "7 Nights • Private Escort",
            imageNames: PackageAsset.carouselImageNames
        )
    }
}
