//
//  ProductOptionsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

/// Lets the user pick one of a product's options, e.g. the flight cabin class,
/// with the package total (and its breakdown) updated below.
struct ProductOptionsView: View {
    private enum Layout {
        static let radioSize: CGFloat = 20
        /// White center of the selected radio, as in the design.
        static let radioDotSize: CGFloat = 8
        static let radioBorderWidth: CGFloat = 2
        static let borderWidth: CGFloat = 1
        static let selectedBorderWidth: CGFloat = 2
        static let noteIconSize: CGFloat = 16
        static let noteIcon = "info.circle"
        static let includedIcon = "checkmark"
        static let includedIconSize: CGFloat = 12
        static let unavailableOpacity: Double = 0.5
    }

    @StateObject private var viewModel: ProductOptionsViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: @autoclosure @escaping () -> ProductOptionsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: Spacing.zero) {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.medium) {
                    Text(viewModel.title)
                        .modifier(AppTextModifier(size: Typography.Size.xLarge, fontWeight: Typography.Weight.semibold))
                        .foregroundStyle(AlmatarColors.textPrimaryStatic)

                    if let note = viewModel.note {
                        noteBanner(note)
                    }

                    VStack(spacing: Spacing.small) {
                        ForEach(viewModel.options, id: \.self) { optionCard($0) }
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.vertical, Spacing.medium)
            }

            PackagePriceFooterView(
                form: viewModel.visitorForm,
                totalLabel: viewModel.totalLabel(visitorCount:),
                amount: viewModel.totalAmountText(visitorCount:),
                detail: viewModel.upgradeDetailText(visitorCount:),
                priceDetailsTitle: viewModel.priceDetailsTitle,
                includedTitle: viewModel.includedTitle,
                breakdownSections: viewModel.breakdownSections,
                buttonTitle: viewModel.continueTitle,
                // The choice is already in the cart; wait for it to be re-priced before going back.
                isLoading: viewModel.isUpdatingCart
            ) {
                dismiss()
            }
        }
        .background(AlmatarColors.backgroundPrimary.ignoresSafeArea())
        .defaultToolbar(title: "")
        .alert(viewModel.errorMessage ?? "", isPresented: isShowingError) {
            Button(viewModel.okTitle, role: .cancel) {}
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    // MARK: - Note

    private func noteBanner(_ note: String) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: Layout.noteIcon)
                .font(.system(size: Layout.noteIconSize, weight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textComplementaryBlue)
                .accessibilityHidden(true)

            Text(note)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textComplementaryBlue)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(Spacing.small)
        .background(AlmatarColors.surfaceInfo)
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
    }

    // MARK: - Option

    private func optionCard(_ option: ProductOption) -> some View {
        let isSelected = viewModel.isSelected(option)
        let isAvailable = viewModel.isAvailable(option)

        return Button {
            viewModel.select(option)
        } label: {
            HStack(alignment: .center, spacing: Spacing.small) {
                radio(isSelected: isSelected)

                VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                    Text(option.title)
                        .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
                        .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    if let subTitle = option.subTitle.nonEmpty {
                        Text(subTitle)
                            .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                            .foregroundStyle(AlmatarColors.textSecondaryStatic)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                priceView(option)
            }
            .padding(Spacing.medium)
            .background(isAvailable ? AlmatarColors.surfaceCard : AlmatarColors.surfaceCardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.large)
                    .stroke(
                        isSelected ? AlmatarColors.borderPrimary : AlmatarColors.borderDefaultCard,
                        lineWidth: isSelected ? Layout.selectedBorderWidth : Layout.borderWidth
                    )
            )
            .opacity(isAvailable ? 1 : Layout.unavailableOpacity)
            .contentShape(RoundedRectangle(cornerRadius: CornerRadius.large))
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// Selected: a solid purple circle with a white center. Unselected: a grey ring.
    @ViewBuilder
    private func radio(isSelected: Bool) -> some View {
        Group {
            if isSelected {
                Circle()
                    .fill(AlmatarColors.surfacePrimaryBase)
                    .overlay(
                        Circle()
                            .fill(AlmatarColors.textOnSurfacePrimary)
                            .frame(width: Layout.radioDotSize, height: Layout.radioDotSize)
                    )
            } else {
                // Drawn inside the frame so it is the same size as the filled selected circle.
                Circle()
                    .strokeBorder(AlmatarColors.iconSecondaryStatic, lineWidth: Layout.radioBorderWidth)
            }
        }
        .frame(width: Layout.radioSize, height: Layout.radioSize)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func priceView(_ option: ProductOption) -> some View {
        if viewModel.isIncluded(option) {
            HStack(spacing: Spacing.xxSmall) {
                Image(systemName: Layout.includedIcon)
                    .font(.system(size: Layout.includedIconSize, weight: Typography.Weight.semibold))
                Text(viewModel.includedTitle)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.medium))
            }
            .foregroundStyle(AlmatarColors.textComplementaryGreen)
        } else {
            VStack(alignment: .trailing, spacing: Spacing.xxxSmall) {
                SUITextPrice(
                    text: viewModel.priceText(option),
                    modifier: AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.semibold)
                )
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(1)
                .fixedSize()

                Text(viewModel.perVisitorTitle)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
            }
        }
    }
}
