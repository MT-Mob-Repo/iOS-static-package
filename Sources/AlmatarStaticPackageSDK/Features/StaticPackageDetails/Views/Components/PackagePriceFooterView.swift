//
//  PackagePriceFooterView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Bottom bar shared by the package screens: the total price row (tap to open the
/// "Price Details" breakdown above it) and the main action button.
/// Observes the visitors form so the visitor count and amounts follow the group size.
struct PackagePriceFooterView: View {
    private enum Layout {
        static let borderWidth: CGFloat = 1
        /// The breakdown scrolls once it is taller than this share of the screen.
        static let maxBreakdownHeightRatio: CGFloat = 0.8
    }

    @ObservedObject var form: VisitorDetailsFormModel
    /// e.g. "Total price • 2 visitors".
    let totalLabel: (_ visitorCount: Int) -> String
    /// Formatted total for the given number of visitors.
    let amount: (_ visitorCount: Int) -> String?
    /// Optional second line, e.g. "+ 1,680 SAR • Cabin upgrade".
    var detail: (_ visitorCount: Int) -> String? = { _ in nil }
    let priceDetailsTitle: String
    let includedTitle: String
    let breakdownSections: [PriceBreakdownSection]
    let buttonTitle: String
    var isLoading = false
    /// Whether the button is disabled for the current form state, e.g. until the travellers' details are complete.
    /// Evaluated on every form change, since this view observes the form.
    var isButtonDisabled: (VisitorDetailsFormModel) -> Bool = { _ in false }
    let onButtonTap: () -> Void

    @State private var isBreakdownExpanded = false
    @State private var breakdownHeight: CGFloat = .zero

    var body: some View {
        let visitorCount = form.visitors.count

        VStack(spacing: Spacing.small) {
            if isBreakdownExpanded {
                breakdown
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .overlay(alignment: .bottom) { line }
            }

            if let amount = amount(visitorCount) {
                Button {
                    withAnimation(.easeInOut) { isBreakdownExpanded.toggle() }
                } label: {
                    TotalPriceSummaryView(
                        form: form,
                        label: totalLabel,
                        amount: amount,
                        detail: detail(visitorCount),
                        isExpanded: isBreakdownExpanded
                    )
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(breakdownSections.isEmpty)
                .padding(.horizontal, Spacing.screenHorizontal)
            }

            PrimaryButton(
                buttonTitle,
                isLoading: isLoading,
                isDisabled: isButtonDisabled(form),
                action: onButtonTap
            )
                .padding(.horizontal, Spacing.screenHorizontal)
        }
        .padding(.top, Spacing.small)
        .padding(.bottom, Spacing.screenBottom)
        .overlay(alignment: .top) { line }
    }

    private var line: some View {
        Rectangle()
            .fill(AlmatarColors.borderDefaultCard)
            .frame(height: Layout.borderWidth)
    }

    /// As tall as its content, scrolling once taller than most of the screen.
    private var breakdown: some View {
        ScrollView {
            PackagePriceBreakdownView(
                title: priceDetailsTitle,
                sections: breakdownSections,
                includedTitle: includedTitle
            )
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.xSmall)
            .readHeight { breakdownHeight = $0 }
        }
        .frame(height: min(breakdownHeight, UIScreen.main.bounds.height * Layout.maxBreakdownHeightRatio))
    }
}
