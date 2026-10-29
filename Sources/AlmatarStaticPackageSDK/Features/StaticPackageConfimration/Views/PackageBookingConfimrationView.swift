//
//  PackageBookingConfimrationView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

struct PackageBookingConfimrationView: View {
    private enum Layout {
        static let borderWidth: CGFloat = 1
        static let receiptIcon = "doc.text"
        static let shareIcon = "square.and.arrow.up"
        static let actionIconSize: CGFloat = 14
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
        .navigationBarBackButtonHidden(true)
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
                        copyAccessibilityLabel: viewModel.copyBookingIdTitle)

                    PackageSummaryView(
                        title: viewModel.packageSummaryTitle,
                        rows: viewModel.summaryRows(for: cart),
                        includesTitle: viewModel.packageIncludesTitle,
                        includes: viewModel.includes(for: cart),
                        addonsTitle: viewModel.yourAddonsTitle,
                        addons: viewModel.addons(for: cart)
                    )

                    let visitors = viewModel.visitors(for: cart)
                    if !visitors.isEmpty {
                        ConfirmationVisitorsView(
                            title: viewModel.visitorsTitle,
                            mainVisitorTitle: viewModel.mainVisitorTitle,
                            verifiedTitle: viewModel.verifiedTitle,
                            visitors: visitors
                        )
                    }

                    let legs = viewModel.flightLegs(for: cart)
                    if !legs.isEmpty {
                        ConfirmationFlightDetailsView(title: viewModel.flightDetailsTitle, legs: legs)
                    }

                    ForEach(viewModel.hotels(for: cart)) { hotel in
                        ConfirmationHotelDetailsView(strings: hotelStrings, hotel: hotel)
                    }

                    PaymentDetailsView(
                        title: viewModel.paymentDetailsTitle,
                        sections: viewModel.paymentSections(for: cart),
                        includedTitle: viewModel.includedAmountTitle,
                        amountText: { viewModel.formattedAmount($0, for: cart) },
                        totalTitle: viewModel.totalPaidTitle,
                        total: viewModel.formattedTotal(for: cart),
                        paidViaText: viewModel.paidViaText(for: cart),
                        paidStatusTitle: viewModel.isPaidInFull(cart) ? viewModel.paidInFullTitle : nil
                    )

                    let tiers = viewModel.cancellationTiers(for: cart)
                    if !tiers.isEmpty {
                        PackageCancellationPolicyView(
                            title: viewModel.cancellationPolicyTitle,
                            tiers: tiers
                        )
                    }

                    documentActions(for: cart)
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.top, Spacing.screenTop)
                .padding(.bottom, Spacing.medium)
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

    private var hotelStrings: ConfirmationHotelDetailsView.Strings {
        ConfirmationHotelDetailsView.Strings(
            title: viewModel.hotelDetailsTitle,
            checkIn: viewModel.checkInTitle,
            checkOut: viewModel.checkOutTitle,
            roomType: viewModel.roomTypeTitle,
            boardBasis: viewModel.boardBasisTitle,
            whatsIncluded: viewModel.whatsIncludedTitle
        )
    }

    // MARK: - Receipt / Share

    private func documentActions(for cart: PackageCart) -> some View {
        HStack(spacing: Spacing.small) {
            if viewModel.isReceiptAvailable {
                Button {
                    viewModel.receiptTapped()
                } label: {
                    outlinedActionLabel(title: viewModel.receiptTitle, icon: Layout.receiptIcon)
                }
                .buttonStyle(.plain)
            }

            ShareLink(item: viewModel.shareText(for: cart)) {
                outlinedActionLabel(title: viewModel.shareItineraryTitle, icon: Layout.shareIcon)
            }
            .buttonStyle(.plain)
        }
    }

    private func outlinedActionLabel(title: String, icon: String) -> some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: icon)
                .font(.system(size: Layout.actionIconSize, weight: Typography.Weight.medium))
                .accessibilityHidden(true)
            Text(title)
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(AlmatarColors.textPrimaryStatic)
        .frame(maxWidth: .infinity)
        .padding(.vertical, Spacing.small)
        .background(AlmatarColors.surfaceCard)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
        )
        .contentShape(Capsule())
    }

    // MARK: - Bottom Actions

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
                    .foregroundStyle(AlmatarColors.textPrimaryInteractive)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.medium)
                    .background(AlmatarColors.surfaceSecondaryBase)
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge))
                    .contentShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge))
            }
            .buttonStyle(.plain)
        }
    }
}
