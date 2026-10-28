//
//  StaticPackageDetailsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

struct StaticPackageDetailsView: View {
    @StateObject private var viewModel: StaticPackageDetailsViewModel
    /// The price breakdown opens above the total when the total is tapped.

    init(viewModel: @autoclosure @escaping () -> StaticPackageDetailsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: Spacing.zero) {
            // Toasts (e.g. "<name> removed.") appear at the bottom of the content, above the payment bar.
            if #available(iOS 26.0, *) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollEdgeEffectHidden(true, for: .top)
                    .toastHost()
            } else {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .toastHost()
            }
               

            if viewModel.packageDetails != nil {
                PackagePriceFooterView(
                    form: viewModel.visitorForm,
                    totalLabel: viewModel.totalPriceLabel(visitorCount:),
                    amount: viewModel.totalPriceAmountText(visitorCount:),
                    detail: viewModel.optionsDetailText(visitorCount:),
                    priceDetailsTitle: viewModel.priceDetailsTitle,
                    includedTitle: viewModel.priceIncludedTitle,
                    breakdownSections: viewModel.priceBreakdownSections,
                    buttonTitle: viewModel.goToPaymentTitle,
                    isLoading: viewModel.isStartingPayment || viewModel.isUpdatingCart,
                    isButtonDisabled: { !$0.areTravellersComplete }
                ) {
                    Task { await viewModel.goToPaymentTapped() }
                }
            }
        }
        .background(AlmatarColors.backgroundPrimary.ignoresSafeArea())
        .defaultToolbar(title: viewModel.headerTitle)
        .toolbarBackground(.hidden, for: .navigationBar)
        // Pushes onto the navigation stack this screen is shown in.
        .navigationDestination(isPresented: isShowingProductOptions) {
            if let index = viewModel.optionsProductIndex,
               let optionsViewModel = viewModel.makeProductOptionsViewModel(productIndex: index) {
                ProductOptionsView(viewModel: optionsViewModel)
                    .environment(\.layoutDirection, AlmatarStaticPackageSDK.shared.configuration.language.layoutDirection)
            }
        }
        .task {
            await viewModel.loadPackageDetails()
        }
        .alert(viewModel.paymentErrorMessage ?? "", isPresented: isShowingPaymentError) {
            Button(viewModel.okTitle, role: .cancel) {}
        }
    }

    private var isShowingPaymentError: Binding<Bool> {
        Binding(
            get: { viewModel.paymentErrorMessage != nil },
            set: { if !$0 { viewModel.paymentErrorMessage = nil } }
        )
    }

    /// Scrolls once taller than half the screen; otherwise as tall as its content.
    private var isShowingProductOptions: Binding<Bool> {
        Binding(
            get: { viewModel.optionsProductIndex != nil },
            set: { if !$0 { viewModel.optionsProductIndex = nil } }
        )
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
        case .loaded:
            ScrollView {
                VStack(spacing: Spacing.xLarge) {
                    PackageDetailsHeaderView(
                        title: viewModel.headerTitle,
                        tags: viewModel.headerTags,
                        metaLine: nil,
                        imageURLs: viewModel.headerImageURLs
                    )

                    VStack(spacing: Spacing.xLarge) {
                        if !viewModel.journeySnapshotItems.isEmpty {
                            JourneySnapshotView(title: viewModel.journeySnapshotTitle, items: viewModel.journeySnapshotItems)
                        }
                        if !viewModel.parkHighlightItems.isEmpty {
                            ParkHighlightsView(title: viewModel.parkHighlightsTitle, items: viewModel.parkHighlightItems)
                        }
                        if !viewModel.packageScheduleItems.isEmpty {
                            PackageScheduleView(
                                title: viewModel.packageScheduleTitle,
                                subTitle: viewModel.packageScheduleSubtitle,
                                items: viewModel.packageScheduleItems,
                                onChangeUpgrade: viewModel.changeUpgradeTapped
                            )
                        }
                        if !viewModel.itineraryDays.isEmpty {
                            ItineraryView(
                                strings: viewModel.itineraryStrings,
                                days: viewModel.itineraryDays,
                                downloadURL: nil,
                                activitySubtitle: viewModel.activitySubtitle,
                                isActivityAdded: viewModel.isActivityAdded,
                                onToggleActivity: viewModel.toggleActivity
                            )
                        }
                        if !viewModel.includedServiceItems.isEmpty {
                            IncludedServicesView(
                                title: viewModel.includedServicesTitle,
                                subtitle: viewModel.includedServicesSubtitle,
                                includedTitle: viewModel.includedInYourPassTitle,
                                items: viewModel.includedServiceItems
                            )
                        }
                        if !viewModel.cancellationTiers.isEmpty {
                            PackageCancellationPolicyView(
                                title: viewModel.cancellationPolicyTitle,
                                tiers: viewModel.cancellationTiers
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)

                    if viewModel.visitorForm.hasContent {
                        // Full-width band on the secondary background, reaching the bottom of the scroll content.
                        VisitorDetailsView(form: viewModel.visitorForm)
                            .padding(.horizontal, Spacing.screenHorizontal)
                            .padding(.top, Spacing.xLarge)
                            .padding(.bottom, Spacing.screenBottom)
                            .background(AlmatarColors.backgroundSecondary)
                    }
                }
                .padding(.bottom, viewModel.visitorForm.hasContent ? Spacing.zero : Spacing.screenBottom)
            }
            .ignoresSafeArea(edges: .top)
            .toolbarBackground(.hidden, for: .navigationBar)
        case .failed(let message):
            VStack(spacing: Spacing.xSmall) {
                Text(message)
                    .font(Typography.TextStyle.body)
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .multilineTextAlignment(.center)
                Button(viewModel.retryTitle) {
                    Task { await viewModel.loadPackageDetails() }
                }
                .font(Typography.TextStyle.body)
                .foregroundStyle(AlmatarColors.textPrimaryInteractive)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }
}
/*
#Preview("English") {
    let _ = AlmatarStaticPackageSDK.shared.setLanguage(.english)
    NavigationStack {
        StaticPackageDetailsView(viewModel: StaticPackageDetailsViewModel(
            cartId: "68d7f1c4a9e2b30f5c1a77de",
            repository: StaticPackagesRepository(baseURL: "https://mock.almatar.com", networkClient: .mock),
            startPayment: { _ in .success(.success) },
            onPaymentFinished: {}
        ))
    }
}

#Preview("Arabic") {
    let _ = AlmatarStaticPackageSDK.shared.setLanguage(.arabic)
    NavigationStack {
        StaticPackageDetailsView(viewModel: StaticPackageDetailsViewModel(
            cartId: "68d7f1c4a9e2b30f5c1a77de",
            repository: StaticPackagesRepository(baseURL: "https://mock.almatar.com", networkClient: .mock),
            startPayment: { _ in .success(.success) },
            onPaymentFinished: {}
        ))
    }
    .environment(\.layoutDirection, .rightToLeft)
}
*/
