//
//  StaticPackageDetailsViewModel.swift
//  AlmatarStaticPackageSDK
//

import Foundation

@MainActor
final class StaticPackageDetailsViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(PackageDetails)
        case failed(message: String)
    }

    @Published private(set) var state: State = .idle

    /// Product ids of the optional itinerary activities the customer added.
    @Published private(set) var addedActivityIds: Set<Int> = []

    // MARK: - Strings
    var goToPaymentTitle: String { LocalizedKey.goToPayment.localized() }
    var journeySnapshotTitle: String { LocalizedKey.journeySnapshot.localized() }
    var parkHighlightsTitle: String { LocalizedKey.parkHighlights.localized() }
    var packageScheduleTitle: String { LocalizedKey.packageSchedule.localized() }
    var includedServicesTitle: String { LocalizedKey.includedServices.localized() }
    var includedServicesSubtitle: String { LocalizedKey.includedServicesSubtitle.localized() }
    var includedInYourPassTitle: String { LocalizedKey.includedInYourPass.localized() }
    var retryTitle: String { LocalizedKey.retry.localized() }
    var itineraryStrings: ItineraryStrings {
        ItineraryStrings(
            title: LocalizedKey.itinerary.localized(),
            subtitle: LocalizedKey.itinerarySubtitle.localized(),
            activities: LocalizedKey.itineraryActivities.localized(),
            included: LocalizedKey.itineraryIncluded.localized(),
            add: LocalizedKey.itineraryAdd.localized(),
            added: LocalizedKey.itineraryAdded.localized(),
            readMore: LocalizedKey.readMore.localized(),
            readLess: LocalizedKey.readLess.localized(),
            dayLabel: { String(format: LocalizedKey.itineraryDay.localized(), $0) }
        )
    }
    private var genericErrorMessage: String { LocalizedKey.genericError.localized() }
    private var dynamicPackageTag: String { LocalizedKey.dynamicPackageTag.localized() }

    var packageDetails: PackageDetails? {
        if case .loaded(let details) = state { return details }
        return nil
    }

    var headerTitle: String {
        packageDetails?.title ?? ""
    }

    var headerDescription: String? {
        packageDetails?.description
    }

    var headerTags: [String] {
        var tags = [dynamicPackageTag]
        if let nights = packageDetails?.durationNights, nights > 0 {
            tags.append(LocalizedKey.nightsTag.localized(with: nights))
        }
        return tags
    }

    var headerMetaLine: String? {
        guard let details = packageDetails,
              let nights = details.durationNights,
              nights > 0 else { return nil }
        let detail = details.destination?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let detail, !detail.isEmpty else {
            return LocalizedKey.nightsTag.localized(with: nights)
        }
        return LocalizedKey.nightsMeta.localized(with: nights, detail)
    }

    /// Asset names for the header carousel (`Assets.xcassets`).
    var headerImageNames: [String] { PackageAsset.carouselImageNames }

    private let packageId: String
    private let repository: StaticPackagesRepositoryProtocol
    private let onGoToPayment: () -> Void

    init(
        packageId: String,
        repository: StaticPackagesRepositoryProtocol,
        onGoToPayment: @escaping () -> Void
    ) {
        self.packageId = packageId
        self.repository = repository
        self.onGoToPayment = onGoToPayment
    }

    func loadPackageDetails() async {
        state = .loading
        do {
            let details = try await repository.fetchPackageDetails(packageId: packageId)
            state = .loaded(details)
        } catch is CancellationError {
            state = .idle
        } catch {
            let apiMessages = (error as? NetworkError)?.apiMessages ?? []
            state = .failed(message: apiMessages.isEmpty ? genericErrorMessage : apiMessages.joined(separator: "\n"))
        }
    }

    func goToPaymentTapped() {
        guard packageDetails != nil else { return }
        onGoToPayment()
    }

    // MARK: - Itinerary
    /// e.g. "Included • 45 min" or "Optional • all day • + SAR 150".
    func activitySubtitle(_ activity: ItineraryActivity) -> String {
        let status = activity.isOptional
            ? LocalizedKey.itineraryOptional.localized()
            : LocalizedKey.itineraryIncluded.localized()
        var parts = [status]
        if let duration = activity.duration.nonEmpty {
            parts.append(duration)
        }
        if activity.isOptional, let price = activity.price {
            parts.append("+ \(price.currency) \(Self.formattedAmount(price.amount))")
        }
        return parts.joined(separator: " • ")
    }

    func isActivityAdded(_ activity: ItineraryActivity) -> Bool {
        addedActivityIds.contains(activity.productId)
    }

    func toggleActivity(_ activity: ItineraryActivity) {
        guard activity.isOptional else { return }
        if addedActivityIds.contains(activity.productId) {
            addedActivityIds.remove(activity.productId)
        } else {
            addedActivityIds.insert(activity.productId)
        }
    }

    private static func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}
