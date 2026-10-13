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
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

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
        case .loaded(let details):
            ScrollView {
                VStack(spacing: Spacing.medium) {
                    PackageDetailsHeaderView(
                        title: viewModel.headerTitle,
                        description: viewModel.headerDescription,
                        tags: viewModel.headerTags,
                        metaLine: viewModel.headerMetaLine,
                        imageNames: viewModel.headerImageNames
                    )

                    VStack(spacing: Spacing.medium) {
                        if let snapshot = details.journeySnapshot, !snapshot.isEmpty {
                            JourneySnapshotView(title: viewModel.journeySnapshotTitle, items: snapshot)
                        }
                        if let highlights = details.parkHighlights, !highlights.isEmpty {
                            ParkHighlightsView(title: viewModel.parkHighlightsTitle, items: highlights)
                        }
                        if let schedule = details.packageSchedule, !schedule.isEmpty {
                            PackageScheduleView(
                                title: viewModel.packageScheduleTitle,
                                subTitle: viewModel.packageScheduleTitle,
                                items: schedule
                            )
                        }
                        if let services = details.includedServices, !services.isEmpty {
                            IncludedServicesView(
                                title: viewModel.includedServicesTitle,
                                subtitle: viewModel.includedServicesSubtitle,
                                includedTitle: viewModel.includedInYourPassTitle,
                                items: services
                            )
                        }
                    }
                    .padding(.horizontal, Spacing.screenHorizontal)
                }
                .padding(.bottom, Spacing.screenBottom)
            }
            .ignoresSafeArea(edges: .top)
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
            packageId: "pkg-001",
            repository: StaticPackagesRepository(baseURL: "https://mock.almatar.com", networkClient: .mock),
            onGoToPayment: {}
        ))
    }
}

#Preview("Arabic") {
    let _ = AlmatarStaticPackageSDK.shared.setLanguage(.arabic)
    NavigationStack {
        StaticPackageDetailsView(viewModel: StaticPackageDetailsViewModel(
            packageId: "pkg-001",
            repository: StaticPackagesRepository(baseURL: "https://mock.almatar.com", networkClient: .mock),
            onGoToPayment: {}
        ))
    }
    .environment(\.layoutDirection, .rightToLeft)
}
