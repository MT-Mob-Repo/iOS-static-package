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
    /// `true` while booking or while the host app's payment flow is open.
    @Published private(set) var isStartingPayment = false
    /// Set when payment cannot start or fails; shown as an alert.
    @Published var paymentErrorMessage: String?

    // MARK: - Strings
    var goToPaymentTitle: String { LocalizedKey.goToPayment.localized() }
    var journeySnapshotTitle: String { LocalizedKey.journeySnapshot.localized() }
    var parkHighlightsTitle: String { LocalizedKey.parkHighlights.localized() }
    var packageScheduleTitle: String { LocalizedKey.packageSchedule.localized() }
    var includedServicesTitle: String { LocalizedKey.includedServices.localized() }
    var includedServicesSubtitle: String { LocalizedKey.includedServicesSubtitle.localized() }
    var includedInYourPassTitle: String { LocalizedKey.includedInYourPass.localized() }
    var retryTitle: String { LocalizedKey.retry.localized() }
    var cancellationPolicyTitle: String { LocalizedKey.cancellationPolicy.localized() }
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

    typealias PaymentResult = AlmatarStaticPackageSDK.PaymentResult

    private let packageId: String
    /// Cart from `POST v1/packages/book`; created on "Go to payment" when missing.
    private var cartId: String?
    private let repository: StaticPackagesRepositoryProtocol
    private let startPayment: (PackagePaymentRequest) async -> PaymentResult
    private let onPaymentFinished: () -> Void

    init(
        packageId: String,
        cartId: String? = nil,
        repository: StaticPackagesRepositoryProtocol,
        startPayment: @escaping (PackagePaymentRequest) async -> PaymentResult,
        onPaymentFinished: @escaping () -> Void
    ) {
        self.packageId = packageId
        self.cartId = cartId
        self.repository = repository
        self.startPayment = startPayment
        self.onPaymentFinished = onPaymentFinished
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

    var okTitle: String { LocalizedKey.ok.localized() }

    /// Package price plus the optional itinerary activities the customer added, in SAR.
    var paymentAmount: Decimal? {
        guard let details = packageDetails else { return nil }
        let activities = details.itinerary?.flatMap { $0.activities ?? [] } ?? []
        let extras = activities
            .filter { addedActivityIds.contains($0.productId) }
            .compactMap { $0.price?.amount }
            .reduce(Decimal.zero, +)
        return details.price.amount + extras
    }

    /// Books the package if needed, then opens the host app's payment flow.
    func goToPaymentTapped() async {
        guard !isStartingPayment, let amount = paymentAmount else { return }
        isStartingPayment = true
        defer { isStartingPayment = false }

        do {
            let cartId = try await currentCartId()
            // TODO: Confirm bookingId / bookingKey mapping with the payment team; the book API returns only `cartId`.
            let request = PackagePaymentRequest(
                bookingId: cartId,
                bookingKey: cartId,
                amountInSar: NSDecimalNumber(decimal: amount).floatValue,
                productType: PackagePaymentRequest.productType
            )
            handlePaymentResult(await startPayment(request))
        } catch is CancellationError {
            return
        } catch {
            let apiMessages = (error as? NetworkError)?.apiMessages ?? []
            paymentErrorMessage = apiMessages.isEmpty ? genericErrorMessage : apiMessages.joined(separator: "\n")
        }
    }

    private func currentCartId() async throws -> String {
        if let cartId { return cartId }
        let booking = try await repository.bookPackage(packageId: packageId)
        cartId = booking.cartId
        return booking.cartId
    }

    private func handlePaymentResult(_ result: PaymentResult) {
        switch result {
        case .success(.success), .success(.pending):
            onPaymentFinished()
        case .success(.failed):
            paymentErrorMessage = genericErrorMessage
        case .failure(.paymentFailed(let reason)), .failure(.validation(let reason)):
            paymentErrorMessage = reason.isEmpty ? genericErrorMessage : reason
        }
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

    // MARK: - Cancellation Policy

    /// Tiers ordered from the earliest cancellation window; a single "Non-refundable" tier
    /// when the package cannot be refunded.
    func cancellationTiers(_ policy: CancellationPolicy) -> [CancellationPolicyTier] {
        let rules = (policy.policies ?? []).sorted { $0.minRemainingHours > $1.minRemainingHours }
        guard policy.isRefundable, !rules.isEmpty else {
            return [CancellationPolicyTier(
                id: 0,
                title: LocalizedKey.cancellationNonRefundable.localized(),
                window: nil,
                note: nil,
                tone: .noRefund
            )]
        }
        return rules.enumerated().map { index, rule in
            let percentage = min(max(rule.refundableAmountPercentage, 0), 100)
            let title: String
            let tone: CancellationPolicyTier.Tone
            switch percentage {
            case 100:
                title = LocalizedKey.cancellationFree.localized()
                tone = .fullRefund
            case 0:
                title = LocalizedKey.cancellationNonRefundable.localized()
                tone = .noRefund
            default:
                title = String(format: LocalizedKey.cancellationPartialRefund.localized(), percentage)
                tone = .partialRefund
            }
            return CancellationPolicyTier(
                id: index,
                title: title,
                window: rule.window.nonEmpty,
                note: rule.note.nonEmpty,
                tone: tone
            )
        }
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
