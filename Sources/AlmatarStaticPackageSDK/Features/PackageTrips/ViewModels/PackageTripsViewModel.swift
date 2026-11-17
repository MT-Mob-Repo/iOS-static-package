//
//  PackageTripsViewModel.swift
//  AlmatarStaticPackageSDK
//

import Foundation

@MainActor
final class PackageTripsViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case loaded
        case failed(message: String)
    }

    private enum Constants {
        static let pageSize = 10
    }

    @Published private(set) var timeframe: PackageTripTimeframe = .upcoming
    @Published private(set) var trips: [PackageTrip] = []
    @Published private(set) var state: State = .loading
    @Published private(set) var isLoadingMore = false
    /// Set when a trip is tapped to push its booking confirmation.
    @Published var selectedTrip: PackageTrip?

    private var total = 0
    private let repository: StaticPackagesRepositoryProtocol

    init(repository: StaticPackagesRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Strings

    var title: String { LocalizedKey.packageTripsTitle.localized() }
    var retryTitle: String { LocalizedKey.retry.localized() }

    func tabTitle(_ timeframe: PackageTripTimeframe) -> String {
        switch timeframe {
        case .upcoming: return LocalizedKey.upcomingTrips.localized()
        case .previous: return LocalizedKey.pastTrips.localized()
        }
    }

    var emptyMessage: String {
        switch timeframe {
        case .upcoming: return LocalizedKey.emptyUpcomingTrips.localized()
        case .previous: return LocalizedKey.emptyPastTrips.localized()
        }
    }

    var isPast: Bool { timeframe == .previous }

    // MARK: - Loading

    /// Loads the first page of the current tab.
    func load() async {
        if trips.isEmpty { state = .loading }
        let requested = timeframe
        do {
            let page = try await repository.fetchPackageTrips(
                timeframe: requested, offset: 0, limit: Constants.pageSize, years: nil
            )
            // The user may have switched tabs while the request was in flight.
            guard requested == timeframe else { return }
            trips = page.trips
            total = page.total
            state = .loaded
        } catch is CancellationError {
            return
        } catch {
            guard requested == timeframe else { return }
            if trips.isEmpty {
                state = .failed(message: Self.message(for: error))
            }
        }
    }

    /// Loads the next page when `trip` is the last one shown.
    func loadMoreIfNeeded(after trip: PackageTrip) async {
        guard trip.id == trips.last?.id, trips.count < total, !isLoadingMore, state == .loaded else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        let requested = timeframe
        do {
            let page = try await repository.fetchPackageTrips(
                timeframe: requested, offset: trips.count, limit: Constants.pageSize, years: nil
            )
            guard requested == timeframe else { return }
            let known = Set(trips.map(\.id))
            trips.append(contentsOf: page.trips.filter { !known.contains($0.id) })
            total = page.total
        } catch {
            // Paging errors are silent; scrolling to the end again retries.
        }
    }

    func select(_ timeframe: PackageTripTimeframe) async {
        guard timeframe != self.timeframe else { return }
        self.timeframe = timeframe
        trips = []
        total = 0
        await load()
    }

    private static func message(for error: Error) -> String {
        let apiMessages = (error as? NetworkError)?.apiMessages ?? []
        return apiMessages.isEmpty ? LocalizedKey.genericError.localized() : apiMessages.joined(separator: "\n")
    }
}
