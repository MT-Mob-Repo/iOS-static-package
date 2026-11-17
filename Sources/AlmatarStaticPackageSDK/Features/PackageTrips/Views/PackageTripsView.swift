//
//  PackageTripsView.swift
//  AlmatarStaticPackageSDK
//
//  My Trips for Static Packages: Upcoming / Past tabs with the user's package
//  bookings. Tapping a trip pushes its booking confirmation.
//

import SwiftUI
import AlmatarSystemDesignSDK

struct PackageTripsView: View {
    private enum Layout {
        static let borderWidth: CGFloat = 1
        static let tabHeight: CGFloat = 36
    }

    @StateObject private var viewModel: PackageTripsViewModel

    init(viewModel: @autoclosure @escaping () -> PackageTripsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel())
    }

    var body: some View {
        VStack(spacing: Spacing.zero) {
            tabs
                .padding(.horizontal, Spacing.medium)
                .padding(.vertical, Spacing.small)

            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(AlmatarColors.backgroundPrimary.ignoresSafeArea())
        .defaultToolbar(title: viewModel.title)
        .navigationDestination(isPresented: isShowingConfirmation) {
            if let trip = viewModel.selectedTrip {
                PackageTripConfirmationView(orderId: trip.orderId)
            }
        }
        .task { await viewModel.load() }
    }

    private var isShowingConfirmation: Binding<Bool> {
        Binding(
            get: { viewModel.selectedTrip != nil },
            set: { if !$0 { viewModel.selectedTrip = nil } }
        )
    }

    // MARK: Tabs

    private var tabs: some View {
        HStack(spacing: Spacing.small) {
            ForEach(PackageTripTimeframe.allCases, id: \.self) { timeframe in
                tabButton(timeframe)
            }
            Spacer(minLength: Spacing.zero)
        }
    }

    private func tabButton(_ timeframe: PackageTripTimeframe) -> some View {
        let isSelected = viewModel.timeframe == timeframe
        return Button {
            Task { await viewModel.select(timeframe) }
        } label: {
            Text(viewModel.tabTitle(timeframe))
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                .foregroundStyle(isSelected ? AlmatarColors.textOnSurfacePrimary : AlmatarColors.textPrimaryStatic)
                .padding(.horizontal, Spacing.medium)
                .frame(height: Layout.tabHeight)
                .background(isSelected ? AlmatarColors.surfacePrimaryBase : AlmatarColors.surfaceCard)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(isSelected ? Color.clear : AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: Content

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .failed(let message):
            errorView(message)
        case .loaded where viewModel.trips.isEmpty:
            ScrollView {
                messageText(viewModel.emptyMessage)
                    .frame(maxWidth: .infinity)
                    .padding(.top, Spacing.xxxLarge)
            }
            .refreshable { await viewModel.load() }
        case .loaded:
            tripsList
        }
    }

    private var tripsList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.medium) {
                ForEach(viewModel.trips) { trip in
                    PackageTripCardView(trip: trip, isPast: viewModel.isPast) {
                        viewModel.selectedTrip = trip
                    }
                    .task { await viewModel.loadMoreIfNeeded(after: trip) }
                }

                if viewModel.isLoadingMore {
                    ProgressView()
                        .padding(.vertical, Spacing.small)
                }
            }
            .padding(.horizontal, Spacing.medium)
            .padding(.vertical, Spacing.small)
        }
        .refreshable { await viewModel.load() }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: Spacing.medium) {
            messageText(message)
            AppButton(viewModel.retryTitle, style: .primary, size: .small) {
                Task { await viewModel.load() }
            }
            .fixedSize()
        }
        .padding(Spacing.medium)
    }

    private func messageText(_ message: String) -> some View {
        Text(message)
            .modifier(AppTextModifier(size: Typography.Size.medium))
            .foregroundStyle(AlmatarColors.textSecondaryStatic)
            .multilineTextAlignment(.center)
    }
}
