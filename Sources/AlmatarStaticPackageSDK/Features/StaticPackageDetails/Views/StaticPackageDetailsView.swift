//
//  StaticPackageDetailsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

struct StaticPackageDetailsView: View {
    @StateObject private var viewModel: StaticPackageDetailsViewModel
    /// The price breakdown opens above the total when the total is tapped.
    @State private var isPriceBreakdownExpanded = false
    @State private var priceBreakdownHeight: CGFloat = .zero

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
                VStack(spacing: Spacing.small) {
                    if isPriceBreakdownExpanded {
                        priceBreakdown
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .overlay(alignment: .bottom) {
                                Rectangle()
                                    .fill(AlmatarColors.borderDefaultCard)
                                    .frame(height: 1)
                            }
                    }

                    if let amount = viewModel.totalPriceAmountText {
                        Button {
                            withAnimation(.easeInOut) { isPriceBreakdownExpanded.toggle() }
                        } label: {
                            TotalPriceSummaryView(
                                form: viewModel.visitorForm,
                                label: viewModel.totalPriceLabel(visitorCount:),
                                amount: amount,
                                isExpanded: isPriceBreakdownExpanded
                            )
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.priceBreakdownSections.isEmpty)
                        .padding(.horizontal, Spacing.screenHorizontal)
                    }

                    PrimaryButton(viewModel.goToPaymentTitle, isLoading: viewModel.isStartingPayment) {
                        Task { await viewModel.goToPaymentTapped() }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                }
                .padding(.top, Spacing.small)
                .padding(.bottom, Spacing.screenBottom)
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(AlmatarColors.borderDefaultCard)
                        .frame(height: 1)
                }
            }
        }
        .background(AlmatarColors.backgroundPrimary.ignoresSafeArea())
        .defaultToolbar(title: viewModel.headerTitle)
        .toolbarBackground(.hidden, for: .navigationBar)
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
    private var priceBreakdown: some View {
        ScrollView {
            PackagePriceBreakdownView(
                title: viewModel.priceDetailsTitle,
                sections: viewModel.priceBreakdownSections,
                includedTitle: viewModel.priceIncludedTitle
            )
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.vertical, Spacing.xSmall)
            .readHeight { priceBreakdownHeight = $0 }
        }
        .frame(height: min(priceBreakdownHeight, UIScreen.main.bounds.height * 0.8))
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
                        imageURLs: viewModel.headerImageURLs,
                        imageNames: viewModel.headerImageNames
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
                                items: viewModel.packageScheduleItems
                            )
                        }
                        if !viewModel.itineraryDays.isEmpty {
                            ItineraryView(
                                strings: viewModel.itineraryStrings,
                                days: viewModel.itineraryDays,
                                downloadURL: viewModel.itineraryDownloadURL,
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
