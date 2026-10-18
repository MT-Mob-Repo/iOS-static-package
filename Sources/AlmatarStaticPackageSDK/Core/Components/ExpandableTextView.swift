//
//  ExpandableTextView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

struct ExpandableTextView: View {
    private enum Layout {
        /// Ignores sub-point rounding differences between the two measured heights.
        static let truncationTolerance: CGFloat = 1
    }

    let text: String
    let collapsedLineLimit: Int
    let readMoreTitle: String
    let readLessTitle: String
    var actionColor: Color = AlmatarColors.textPrimaryStatic

    @State private var isExpanded = false
    @State private var fullHeight: CGFloat = .zero
    @State private var collapsedHeight: CGFloat = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            styledText
                .lineLimit(isExpanded ? nil : collapsedLineLimit)
                .fixedSize(horizontal: false, vertical: true)
                .background(heightReader { height in
                    if !isExpanded { collapsedHeight = height }
                })
                // Unlimited copy, measured off-screen to know whether the visible text is cut.
                .background(
                    styledText
                        .fixedSize(horizontal: false, vertical: true)
                        .hidden()
                        .background(heightReader { fullHeight = $0 })
                )

            if isExpanded || isTruncated {
                Button {
                    withAnimation(.easeInOut) { isExpanded.toggle() }
                } label: {
                    Text(isExpanded ? readLessTitle : readMoreTitle)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.medium))
                        .foregroundStyle(actionColor)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var isTruncated: Bool {
        fullHeight > collapsedHeight + Layout.truncationTolerance
    }

    private var styledText: some View {
        Text(text)
            .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
            .foregroundStyle(AlmatarColors.textSecondaryStatic)
    }

    private func heightReader(_ onChange: @escaping (CGFloat) -> Void) -> some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear { onChange(proxy.size.height) }
                .onChange(of: proxy.size.height) { onChange($0) }
        }
    }
}
