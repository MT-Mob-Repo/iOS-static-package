//
//  StaticPackageDetailsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI

struct StaticPackageDetailsView: View {
    @StateObject private var viewModel: StaticPackageDetailsViewModel

    init(viewModel: @autoclosure @escaping () -> StaticPackageDetailsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: Spacing.medium) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            PrimaryButton(viewModel.goToPaymentTitle, isDisabled: viewModel.packageDetails == nil) {
                viewModel.goToPaymentTapped()
            }
            .padding(.horizontal, Spacing.screenHorizontal)
            .padding(.bottom, Spacing.screenBottom)
        }
        .background(AlmatarColors.backgroundPrimary.ignoresSafeArea())
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
            Text(details.title)
                .font(Typography.title)
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .padding(.horizontal, Spacing.screenHorizontal)
        case .failed(let message):
            VStack(spacing: Spacing.xSmall) {
                Text(message)
                    .font(Typography.body)
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .multilineTextAlignment(.center)
                Button(viewModel.retryTitle) {
                    Task { await viewModel.loadPackageDetails() }
                }
                .font(Typography.body)
                .foregroundStyle(AlmatarColors.textPrimaryInteractive)
            }
            .padding(.horizontal, Spacing.screenHorizontal)
        }
    }
}

#Preview("English") {
    StaticPackageDetailsView(viewModel: StaticPackageDetailsViewModel(
        packageId: "pkg-001",
        language: .english,
        repository: StaticPackagesRepository(baseURL: "https://mock.almatar.com", networkClient: .mock),
        onGoToPayment: {}
    ))
}

#Preview("Arabic") {
    StaticPackageDetailsView(viewModel: StaticPackageDetailsViewModel(
        packageId: "pkg-001",
        language: .arabic,
        repository: StaticPackagesRepository(baseURL: "https://mock.almatar.com", networkClient: .mock),
        onGoToPayment: {}
    ))
    .environment(\.layoutDirection, .rightToLeft)
}
