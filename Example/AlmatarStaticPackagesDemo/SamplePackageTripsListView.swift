//
//  SamplePackageTripsListView.swift
//  MyApp
//
//  Shows how a host app can merge package trips into its own My Trips list:
//  it calls `fetchPackageTrips` itself, pages through the results, and renders
//  each trip with the SDK's card.
//

import SwiftUI
import AlmatarStaticPackageSDK

struct SamplePackageTripsListView: View {

    private let sdk = AlmatarStaticPackageSDK.shared
    private let pageSize = 10

    @State private var timeframe: PackageTripTimeframe = .upcoming
    @State private var trips: [PackageTrip] = []
    @State private var total = 0
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedOrderId: String?
    /// Bumped on every reload so responses from an older tab or refresh are ignored.
    @State private var generation = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("Timeframe", selection: $timeframe) {
                Text("Upcoming").tag(PackageTripTimeframe.upcoming)
                Text("Past").tag(PackageTripTimeframe.previous)
            }
            .pickerStyle(.segmented)
            .padding(16)

            content
        }
        .navigationTitle("Sample trips list")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: timeframe) { await reload() }
        .navigationDestination(isPresented: isShowingConfirmation) {
            if let selectedOrderId {
                sdk.getPackageTripConfirmationView(orderId: selectedOrderId) {
                    self.selectedOrderId = nil
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if trips.isEmpty && isLoading {
            ProgressView().frame(maxHeight: .infinity)
        } else if trips.isEmpty, let errorMessage {
            VStack(spacing: 12) {
                Text(errorMessage)
                    .multilineTextAlignment(.center)
                Button("Retry") { Task { await reload() } }
            }
            .padding(16)
            .frame(maxHeight: .infinity)
        } else if trips.isEmpty {
            Text("No trips")
                .foregroundStyle(.secondary)
                .frame(maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    Text("\(trips.count) of \(total) trips")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(trips) { trip in
                        sdk.getPackageTripCardView(trip: trip, isPast: timeframe == .previous) {
                            selectedOrderId = trip.orderId
                        }
                        .onAppear {
                            if trip.id == trips.last?.id {
                                Task { await loadNextPage() }
                            }
                        }
                    }

                    if isLoading {
                        ProgressView().padding(.vertical, 8)
                    }
                }
                .padding(16)
            }
            .refreshable { await reload() }
        }
    }

    private var isShowingConfirmation: Binding<Bool> {
        Binding(
            get: { selectedOrderId != nil },
            set: { if !$0 { selectedOrderId = nil } }
        )
    }

    // MARK: - Loading

    private func reload() async {
        generation += 1
        trips = []
        total = 0
        errorMessage = nil
        isLoading = false
        await loadNextPage()
    }

    private func loadNextPage() async {
        guard !isLoading, trips.isEmpty || trips.count < total else { return }
        let request = generation
        isLoading = true

        do {
            let page = try await sdk.fetchPackageTrips(
                timeframe: timeframe,
                offset: trips.count,
                limit: pageSize
            )
            guard request == generation else { return } // a newer reload replaced this request
            trips += page.trips
            total = page.total
        } catch {
            guard request == generation else { return }
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
