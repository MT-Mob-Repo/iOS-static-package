//
//  StaticPackageDetailsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

struct StaticPackageDetailsView: View {
    @StateObject private var viewModel: StaticPackageDetailsViewModel

    init(viewModel: @autoclosure @escaping () -> StaticPackageDetailsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: Spacing.zero) {
            if #available(iOS 26.0, *) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollEdgeEffectHidden(true, for: .top)
            } else {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
               

            if viewModel.packageDetails != nil {
                PrimaryButton(viewModel.goToPaymentTitle, isDisabled: false) {
                    viewModel.goToPaymentTapped()
                }
                .padding(.horizontal, Spacing.screenHorizontal)
                .padding(.bottom, Spacing.screenBottom)
            }
        }
        .background(AlmatarColors.backgroundPrimary.ignoresSafeArea())
        .defaultToolbar(title: viewModel.headerTitle)
        .toolbarBackground(.hidden, for: .navigationBar)
        .task {
            await viewModel.loadPackageDetails()
        }
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
                            CancellationPolicyView(
                                title: viewModel.cancellationPolicyTitle,
                                tiers: viewModel.cancellationTiers
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                }
                .padding(.bottom, Spacing.screenBottom)
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

#Preview("English") {
    let _ = AlmatarStaticPackageSDK.shared.setLanguage(.english)
    NavigationStack {
        StaticPackageDetailsView(viewModel: StaticPackageDetailsViewModel(
            cartId: "68d7f1c4a9e2b30f5c1a77de",
            repository: StaticPackagesRepository(baseURL: "https://mock.almatar.com", networkClient: .mock),
            onGoToPayment: {}
        ))
    }
}

#Preview("Arabic") {
    let _ = AlmatarStaticPackageSDK.shared.setLanguage(.arabic)
    NavigationStack {
        StaticPackageDetailsView(viewModel: StaticPackageDetailsViewModel(
            cartId: "68d7f1c4a9e2b30f5c1a77de",
            repository: StaticPackagesRepository(baseURL: "https://mock.almatar.com", networkClient: .mock),
            onGoToPayment: {}
        ))
    }
    .environment(\.layoutDirection, .rightToLeft)
}
