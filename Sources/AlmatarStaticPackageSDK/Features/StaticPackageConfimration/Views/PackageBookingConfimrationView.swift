//
//  PackageBookingConfimrationView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

struct PackageBookingConfimrationView: View {
    private enum Layout {
        static let borderWidth: CGFloat = 1
    }

    @StateObject private var viewModel: PackageBookingConfimrationViewModel

    init(viewModel: @autoclosure @escaping () -> PackageBookingConfimrationViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: Spacing.medium) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            actions
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.screenBottom)
        }
        .background(AlmatarColors.backgroundPrimary.ignoresSafeArea())
        .task {
            await viewModel.loadCart()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded(let cart):
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    BookingConfirmationHeaderView(
                        title: viewModel.titleText,
                        subtitle: viewModel.subtitleText,
                        bookingIdTitle: viewModel.bookingIdTitle,
                        bookingId: cart.bookingReference,
                        copyAccessibilityLabel: viewModel.copyBookingIdTitle,
                        onCopy: { viewModel.copyBookingIdTapped() }
                    )

                    PackageSummaryView(
                        title: viewModel.packageSummaryTitle,
                        rows: viewModel.summaryRows(for: cart),
                        includesTitle: viewModel.packageIncludesTitle,
                        includes: viewModel.includes(for: cart)
                    )

                    PaymentDetailsView(
                        title: viewModel.paymentDetailsTitle,
                        lines: viewModel.paymentLines(for: cart),
                        totalTitle: viewModel.totalPaidTitle,
                        total: viewModel.formattedTotal(for: cart)
                    )

                    let tiers = viewModel.cancellationTiers(for: cart)
                    if !tiers.isEmpty {
                        CancellationPolicyView(
                            title: viewModel.cancellationPolicyTitle,
                            tiers: tiers
                        )
                    }
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.screenTop)
            }
        case .failed(let message):
            VStack(spacing: Spacing.xSmall) {
                Text(message)
                    .font(Typography.TextStyle.body)
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .multilineTextAlignment(.center)
                Button(viewModel.retryTitle) {
                    Task { await viewModel.loadCart() }
                }
                .font(Typography.TextStyle.body)
                .foregroundStyle(AlmatarColors.textPrimaryInteractive)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }

    // The booking is already confirmed, so both actions stay enabled even if the cart fails to load.
    private var actions: some View {
        VStack(spacing: Spacing.small) {
            PrimaryButton(viewModel.goToMyTripsTitle, isDisabled: false) {
                viewModel.goToMyTripsTapped()
            }

            Button {
                viewModel.backToHomeTapped()
            } label: {
                Text(viewModel.backToHomeTitle)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.medium)
                    .background(AlmatarColors.surfaceCardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge))
                    .overlay(
                        RoundedRectangle(cornerRadius: CornerRadius.xLarge)
                            .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
                    )
            }
            .buttonStyle(.plain)
        }
    }
}
