//
//  PackageDetailsHeaderView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import UIKit
import AlmatarSystemDesignSDK

struct PackageDetailsHeaderView: View {
    private enum Layout {
        static let headerHeight: CGFloat = 420
        /// How far the card sits up over the carousel image.
        static let cardOverlap: CGFloat = 45
        static let cardHorizontalInset: CGFloat = 16
        static let cardCornerRadius: CGFloat = CornerRadius.xxxLarge
        static let borderWidth: CGFloat = 1
        static let pageDotSize: CGFloat = 7
        static let pageDotSpacing: CGFloat = 6
        static let pageDotsBottomPadding: CGFloat = 12
        static let shadowColor = Color(red: 24 / 255, green: 39 / 255, blue: 75 / 255).opacity(0.12)
    }

    let title: String
    let tags: [String]
    let metaLine: String?
    /// Remote carousel images; when empty, `imageNames` are shown instead.
    var imageURLs: [URL] = []

    @State private var currentPage = 0

    private var slideCount: Int {
        imageURLs.count
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
        remoteSlide(at: index)
    }

    private func remoteSlide(at index: Int) -> some View {
        AsyncImage(url: imageURLs[index]) { phase in
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
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
            tagsRow

            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.xLarge, fontWeight: Typography.Weight.bold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .fixedSize(horizontal: false, vertical: true)
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
}
