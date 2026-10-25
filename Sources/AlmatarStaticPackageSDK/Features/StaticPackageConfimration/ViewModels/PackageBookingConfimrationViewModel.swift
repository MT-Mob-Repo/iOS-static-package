//
//  PackageBookingConfimrationViewModel.swift
//  AlmatarStaticPackageSDK
//

import Foundation
import UIKit

@MainActor
final class PackageBookingConfimrationViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(PackageCart)
        case failed(message: String)
    }

    private enum Constants {
        static let priceLocale = Locale(identifier: "en_US")
        static let maxPriceFractionDigits = 2
        static let apiDateFormat = "yyyy-MM-dd"
        static let dateRangeSeparator = " – "
    }

    @Published private(set) var state: State = .idle

    // MARK: - Strings
    var titleText: String { LocalizedKey.bookingConfirmedTitle.localized() }
    var subtitleText: String { LocalizedKey.bookingConfirmedSubtitle.localized() }
    var bookingIdTitle: String { LocalizedKey.bookingId.localized() }
    var copyBookingIdTitle: String { LocalizedKey.copyBookingId.localized() }
    var packageSummaryTitle: String { LocalizedKey.packageSummary.localized() }
    var packageIncludesTitle: String { LocalizedKey.packageIncludes.localized() }
    var paymentDetailsTitle: String { LocalizedKey.paymentDetails.localized() }
    var totalPaidTitle: String { LocalizedKey.totalPaid.localized() }
    var cancellationPolicyTitle: String { LocalizedKey.cancellationPolicy.localized() }
    var goToMyTripsTitle: String { LocalizedKey.goToMyTrips.localized() }
    var backToHomeTitle: String { LocalizedKey.backToHome.localized() }
    var retryTitle: String { LocalizedKey.retry.localized() }
    private var genericErrorMessage: String { LocalizedKey.genericError.localized() }

    var cart: PackageCart? {
        if case .loaded(let cart) = state { return cart }
        return nil
    }

    private let id: String
    private let repository: StaticPackagesRepositoryProtocol
    private let onGoToMyTrips: () -> Void
    private let onBackToHome: () -> Void

    init(
        id: String,
        repository: StaticPackagesRepositoryProtocol,
        onGoToMyTrips: @escaping () -> Void,
        onBackToHome: @escaping () -> Void
    ) {
        self.id = id
        self.repository = repository
        self.onGoToMyTrips = onGoToMyTrips
        self.onBackToHome = onBackToHome
    }

    // MARK: - Loading

    func loadCart() async {
        state = .loading
        do {
            let cart = try await repository.fetchCart(id: id)
            state = .loaded(cart)
        } catch is CancellationError {
            state = .idle
        } catch {
            let apiMessages = (error as? NetworkError)?.apiMessages ?? []
            state = .failed(message: apiMessages.isEmpty ? genericErrorMessage : apiMessages.joined(separator: "\n"))
        }
    }

    // MARK: - Actions

    func goToMyTripsTapped() {
        onGoToMyTrips()
    }

    func backToHomeTapped() {
        onBackToHome()
    }

    func copyBookingIdTapped() {
        guard let cart else { return }
        UIPasteboard.general.string = cart.bookingReference
    }

    // MARK: - Display Data

    func summaryRows(for cart: PackageCart) -> [PackageSummaryRow] {
        let summary = cart.packageSummary
        var rows = [PackageSummaryRow(label: LocalizedKey.package.localized(), value: summary.title)]
        if let destination = summary.destination.nonEmpty {
            rows.append(PackageSummaryRow(label: LocalizedKey.destination.localized(), value: destination))
        }
        if let dates = formattedDateRange(from: summary.startDate, to: summary.endDate) {
            rows.append(PackageSummaryRow(label: LocalizedKey.duration.localized(), value: dates))
        }
        if let badge = summary.badges?.first.nonEmpty {
            rows.append(PackageSummaryRow(label: LocalizedKey.tier.localized(), value: badge, isBadge: true))
        }
        return rows
    }

    func includes(for cart: PackageCart) -> [JourneySnapshotItem] {
        cart.packageSummary.includes ?? []
    }

    /// One line per priced item in the payment breakdown; total rows are shown separately.
    func paymentLines(for cart: PackageCart) -> [PaymentDetailsLine] {
        let currency = cart.payment.currency
        return (cart.payment.breakdown ?? []).flatMap { section in
            (section.items ?? []).map { item in
                PaymentDetailsLine(
                    title: item.label,
                    subtitle: item.description.nonEmpty,
                    quantity: nil,
                    amount: formattedPrice(Decimal(item.amount), currency: currency)
                )
            }
        }
    }

    func formattedTotal(for cart: PackageCart) -> String {
        formattedPrice(cart.payment.totalPaid, currency: cart.payment.currency)
    }

    /// Tiers in the order returned by the API (earliest cancellation window first).
    func cancellationTiers(for cart: PackageCart) -> [CancellationPolicyTier] {
        (cart.cancellationPolicies ?? []).enumerated().map { index, policy in
            CancellationPolicyTier(
                id: index,
                title: policy.title.nonEmpty ?? "",
                window: tierWindow(for: policy),
                note: policy.note.nonEmpty
            )
        }
    }

    // MARK: - Formatting

    private func formattedPrice(_ amount: Decimal, currency: String) -> String {
        let value = amount.formatted(
            .number
                .precision(.fractionLength(0...Constants.maxPriceFractionDigits))
                .locale(Constants.priceLocale)
        )
        return "\(currency) \(value)"
    }

    private func tierWindow(for policy: CancellationPolicy) -> String? {
        let window = policy.window.nonEmpty
        guard let until = policy.until.nonEmpty else { return window }
        let untilText = "\(LocalizedKey.until.localized()) \(until)"
        guard let window else { return untilText }
        return "\(window) \(untilText)"
    }

    private func formattedDateRange(from start: String?, to end: String?) -> String? {
        let dates = [start, end].compactMap { formattedDate($0.nonEmpty) }
        return dates.isEmpty ? nil : dates.joined(separator: Constants.dateRangeSeparator)
    }

    /// "yyyy-MM-dd" from the API as a medium date, or the raw value when it cannot be parsed.
    private func formattedDate(_ value: String?) -> String? {
        guard let value else { return nil }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = Constants.apiDateFormat
        guard let date = parser.date(from: value) else { return value }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}
