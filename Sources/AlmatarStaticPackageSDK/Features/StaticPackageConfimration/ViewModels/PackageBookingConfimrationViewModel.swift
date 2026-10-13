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
        static let maxPercentageFractionDigits = 1
        static let percentSign = "%"
        static let fullRefundPercentage: Double = 100
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

    private let cartId: String
    private let repository: StaticPackagesRepositoryProtocol
    private let onGoToMyTrips: () -> Void
    private let onBackToHome: () -> Void

    init(
        cartId: String,
        repository: StaticPackagesRepositoryProtocol,
        onGoToMyTrips: @escaping () -> Void,
        onBackToHome: @escaping () -> Void
    ) {
        self.cartId = cartId
        self.repository = repository
        self.onGoToMyTrips = onGoToMyTrips
        self.onBackToHome = onBackToHome
    }

    // MARK: - Loading

    func loadCart() async {
        state = .loading
        do {
            let cart = try await repository.fetchCart(cartId: cartId)
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
        UIPasteboard.general.string = cart.cartId
    }

    // MARK: - Display Data

    func summaryRows(for cart: PackageCart) -> [PackageSummaryRow] {
        var rows = [PackageSummaryRow(label: LocalizedKey.package.localized(), value: cart.name)]
        if let destination = cart.destination.nonEmpty {
            rows.append(PackageSummaryRow(label: LocalizedKey.destination.localized(), value: destination))
        }
        if let duration = cart.duration.nonEmpty {
            rows.append(PackageSummaryRow(label: LocalizedKey.duration.localized(), value: duration))
        }
        if let tier = cart.tier.nonEmpty {
            rows.append(PackageSummaryRow(label: LocalizedKey.tier.localized(), value: tier, isBadge: true))
        }
        return rows
    }

    /// One line per product priced through its add-on info.
    func paymentLines(for cart: PackageCart) -> [PaymentDetailsLine] {
        (cart.products ?? []).compactMap { product in
            guard let addon = product.addonInfo else { return nil }
            let quantity = addon.quantity ?? 1
            return PaymentDetailsLine(
                title: addon.title,
                subtitle: addon.subtitle.nonEmpty,
                quantity: quantity > 1 ? quantity : nil,
                amount: formattedPrice(addon.price * Decimal(quantity), currency: addon.currency)
            )
        }
    }

    func formattedTotal(for cart: PackageCart) -> String {
        formattedPrice(cart.price.finalAmount, currency: cart.price.currency)
    }

    func cancellationStatusTitle(for policy: CartCancellationPolicy) -> String {
        policy.isRefundable
            ? LocalizedKey.freeCancellation.localized()
            : LocalizedKey.nonRefundable.localized()
    }

    func cancellationItems(for policy: CartCancellationPolicy) -> [CancellationPolicyItem] {
        (policy.policies ?? []).map { rule in
            CancellationPolicyItem(
                window: rule.window.nonEmpty,
                note: rule.note.nonEmpty,
                refundTitle: LocalizedKey.refundPercentage.localized(formattedPercentage(rule.refundableAmountPercentage)),
                isFullRefund: rule.refundableAmountPercentage >= Constants.fullRefundPercentage
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

    private func formattedPercentage(_ value: Double) -> String {
        let number = value.formatted(
            .number
                .precision(.fractionLength(0...Constants.maxPercentageFractionDigits))
                .locale(Constants.priceLocale)
        )
        return number + Constants.percentSign
    }
}

private extension Optional where Wrapped == String {
    /// The string, or `nil` when it is missing or blank.
    var nonEmpty: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}
