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
        static let posixLocale = Locale(identifier: "en_US_POSIX")
        static let utc = TimeZone(identifier: "UTC")!
        static let maxPriceFractionDigits = 2
        static let apiDateFormat = "yyyy-MM-dd"
        static let shortDateTemplate = "EEEdMMM"
        static let fullDateTemplate = "EEEdMMMyyyy"
        static let dateRangeSeparator = " – "
        static let separator = " • "
        static let titleSeparator = " · "
        static let addonIcon = "ticket"
        static let paidStatuses: Set<String> = ["success", "succeeded"]
        static let maxStars = 5
    }

    @Published private(set) var state: State = .idle

    // MARK: - Strings
    var titleText: String { LocalizedKey.bookingConfirmedTitle.localized() }
    var subtitleText: String { LocalizedKey.bookingConfirmedSubtitle.localized() }
    var bookingIdTitle: String { LocalizedKey.bookingId.localized() }
    var copyBookingIdTitle: String { LocalizedKey.copyBookingId.localized() }
    var packageSummaryTitle: String { LocalizedKey.packageSummary.localized() }
    var packageIncludesTitle: String { LocalizedKey.packageIncludes.localized() }
    var yourAddonsTitle: String { LocalizedKey.yourAddons.localized() }
    var visitorsTitle: String { LocalizedKey.confirmationVisitors.localized() }
    var mainVisitorTitle: String { LocalizedKey.mainVisitor.localized() }
    var verifiedTitle: String { LocalizedKey.verified.localized() }
    var flightDetailsTitle: String { LocalizedKey.flightDetails.localized() }
    var hotelDetailsTitle: String { LocalizedKey.hotelDetails.localized() }
    var checkInTitle: String { LocalizedKey.checkIn.localized() }
    var checkOutTitle: String { LocalizedKey.checkOut.localized() }
    var roomTypeTitle: String { LocalizedKey.roomType.localized() }
    var boardBasisTitle: String { LocalizedKey.boardBasis.localized() }
    var whatsIncludedTitle: String { LocalizedKey.whatsIncluded.localized() }
    var paymentDetailsTitle: String { LocalizedKey.paymentDetails.localized() }
    var totalPaidTitle: String { LocalizedKey.totalPaid.localized() }
    var paidInFullTitle: String { LocalizedKey.paidInFull.localized() }
    var cancellationPolicyTitle: String { LocalizedKey.bookingCancellationPolicy.localized() }
    var receiptTitle: String { LocalizedKey.receipt.localized() }
    var shareItineraryTitle: String { LocalizedKey.shareItinerary.localized() }
    var goToMyTripsTitle: String { LocalizedKey.goToMyTrips.localized() }
    var backToHomeTitle: String { LocalizedKey.backToHome.localized() }
    var retryTitle: String { LocalizedKey.retry.localized() }
    private var genericErrorMessage: String { LocalizedKey.genericError.localized() }
    var includedAmountTitle: String { LocalizedKey.includedAmount.localized() }

    var cart: PackageCart? {
        if case .loaded(let cart) = state { return cart }
        return nil
    }

    /// The receipt button is shown only when the host app handles it.
    var isReceiptAvailable: Bool { onViewReceipt != nil }

    private let id: String
    private let repository: StaticPackagesRepositoryProtocol
    private let onGoToMyTrips: () -> Void
    private let onBackToHome: () -> Void
    private let onViewReceipt: ((String) -> Void)?

    init(
        id: String,
        repository: StaticPackagesRepositoryProtocol,
        onGoToMyTrips: @escaping () -> Void,
        onBackToHome: @escaping () -> Void,
        onViewReceipt: ((String) -> Void)? = nil
    ) {
        self.id = id
        self.repository = repository
        self.onGoToMyTrips = onGoToMyTrips
        self.onBackToHome = onBackToHome
        self.onViewReceipt = onViewReceipt
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

    func receiptTapped() {
        guard let orderId = cart?.orderId.nonEmpty else { return }
        onViewReceipt?(orderId)
    }

    func copyBookingIdTapped() {
        guard let bookingReference = cart?.bookingReference.nonEmpty else { return }
        UIPasteboard.general.string = bookingReference
    }

    // MARK: - Package Summary

    func summaryRows(for cart: PackageCart) -> [PackageSummaryRow] {
        var rows: [PackageSummaryRow] = []
        if let name = (cart.packageInfo?.name).nonEmpty {
            rows.append(PackageSummaryRow(label: LocalizedKey.package.localized(), value: name))
        }
        if let destination = cart.packageInfo?.journeySnapshot?.first?.label {
            rows.append(PackageSummaryRow(label: LocalizedKey.destination.localized(), value: destination))
        }
        // Dates the customer picked in the booking form; each may be "yyyy-MM-dd" or an ISO 8601 date-time.
        let selectedDates = cart.sections?.departureDate
        let startDate = selectedDates?.departureDate
        let endDate = selectedDates?.returnDate
        if let dates = formattedDateRange(from: startDate, to: endDate) {
            rows.append(PackageSummaryRow(label: LocalizedKey.dates.localized(), value: dates))
        }
        if let visitors = visitorsCountText(cart.travellers?.count) {
            rows.append(PackageSummaryRow(label: LocalizedKey.confirmationVisitors.localized(), value: visitors))
        }
        return rows
    }

    func includes(for cart: PackageCart) -> [JourneySnapshotItem] {
        Array(cart.packageInfo?.journeySnapshot?.dropFirst() ?? [])
    }

    /// Optional add-ons the customer picked, e.g. "Fast Pass — Skip the Line • 2 visitors".
    func addons(for cart: PackageCart) -> [JourneySnapshotItem] {
       return []
    }

    /// Quantity booked for `product`, matched by add-on id in `cart.products`.
    private func bookedQuantity(of product: PackageProduct, in cart: PackageCart) -> Int? {
        let addonId = product.addonInfo?.id.map { String($0) }
        guard let id = addonId ?? product.productId?.value else { return nil }
        return cart.products?.first { $0.addonInfo?.id?.value == id || $0.option?.id?.value == id }?.addonInfo?.quantity
    }

    // MARK: - Visitors

    /// Main visitor first, then the others in the order returned by the API.
    func visitors(for cart: PackageCart) -> [CartTraveller] {
        let travellers = cart.travellers ?? []
        return travellers.filter(\.isMainGuest) + travellers.filter { !$0.isMainGuest }
    }

    // MARK: - Flights

    /// First leg is the departure, last leg the return.
    /// `route` holds the leg title, e.g. "Departure · Thu 16 Jul 2026".
    func flightLegs(for cart: PackageCart) -> [PackageScheduleFlightLeg] {
        let legs = cart.packageProducts
            .filter { $0.productType == .flight }
            .flatMap { $0.flightInfo?.legs ?? [] }
        return legs.enumerated().map { index, leg in
            let label: String?
            switch index {
            case 0: label = LocalizedKey.departure.localized()
            case legs.count - 1: label = LocalizedKey.returnFlight.localized()
            default: label = nil
            }
            let date = parseDateTime(leg.departure.time).map { fullDateFormatter.string(from: $0) }
            let title = [label, date].compactMap { $0 }.joined(separator: Constants.titleSeparator)
            let subtitle = [leg.flightNumber.nonEmpty, leg.cabinClass.nonEmpty].compactMap { $0 }
            let durationInfo = [leg.duration.nonEmpty, stopsText(leg.stops)].compactMap { $0 }
            return PackageScheduleFlightLeg(
                isUpgraded: false,
                airlineLogoUrl: leg.airline?.logoUrl,
                route: title,
                subtitle: subtitle.isEmpty ? nil : subtitle.joined(separator: Constants.titleSeparator),
                departureTime: wallClockTime(leg.departure.time),
                departureLocation: locationText(leg.departure),
                arrivalTime: wallClockTime(leg.arrival.time),
                arrivalLocation: locationText(leg.arrival),
                durationInfo: durationInfo.isEmpty ? nil : durationInfo.joined(separator: Constants.separator),
                stopCodes: leg.stopovers.compactMap { $0.airportCode.nonEmpty }
            )
        }
    }

    // MARK: - Hotels

    func hotels(for cart: PackageCart) -> [ConfirmationHotel] {
        cart.packageProducts.enumerated().compactMap { index, product in
            guard product.productType == .hotel, let hotel = product.hotelInfo else { return nil }
            return ConfirmationHotel(
                id: index,
                imageURL: hotel.imageUrl.nonEmpty.flatMap(URL.init(string:)),
                name: product.title,
                location: hotel.city.nonEmpty,
                stars: hotel.starRating.map { min(Constants.maxStars, max(0, Int($0.rounded()))) } ?? 0,
                checkIn: formattedDate(hotel.checkIn),
                checkOut: formattedDate(hotel.checkOut),
                roomType: (hotel.room?.name).nonEmpty,
                boardBasis: hotel.boardBasis.nonEmpty,
                amenities: (hotel.tags ?? []).map { JourneySnapshotItem(icon: $0.icon ?? "", label: $0.label) }
            )
        }
    }

    // MARK: - Payment

    /// Titles of the mandatory package products (flight, hotel, included add-ons), shown as "Included".
    func includedProducts(for cart: PackageCart) -> [String] {
        cart.packageProducts
            .compactMap { product in
                return product.title ?? ""
            }
    }

    /// Priced items grouped by breakdown section, as returned by the API.
    func paymentSections(for cart: PackageCart) -> [PriceBreakdownSection] {
        cart.payment?.breakdown ?? []
    }

    /// e.g. "SAR 300".
    func formattedAmount(_ amount: Double, for cart: PackageCart) -> String {
        formattedPrice(Decimal(amount), currency: currency(for: cart))
    }

    func formattedTotal(for cart: PackageCart) -> String {
        formattedPrice(cart.payment?.totalPaid ?? 0, currency: currency(for: cart))
    }

    /// e.g. "Paid via Visa ending 4629".
    func paidViaText(for cart: PackageCart) -> String? {
        guard let method = cart.payment?.paymentMethod,
              let brand = method.brand.nonEmpty,
              let last4 = method.last4.nonEmpty else { return nil }
        return LocalizedKey.paidVia.localized(with: brand, last4)
    }

    func isPaidInFull(_ cart: PackageCart) -> Bool {
        Constants.paidStatuses.contains(cart.payment?.status?.lowercased() ?? "")
    }

    // MARK: - Cancellation

    /// Tiers in the order returned by the API (earliest cancellation window first).
    func cancellationTiers(for cart: PackageCart) -> [CancellationPolicyTier] {
        (cart.cancellationPolicies ?? []).enumerated().map { index, policy in
            CancellationPolicyTier(
                id: index,
                title: policy.title.nonEmpty ?? defaultTierTitle(policy.refundableAmountPercentage),
                window: tierWindow(for: policy),
                note: policy.note.nonEmpty
            )
        }
    }

    // MARK: - Share

    /// Plain-text itinerary shared from "Share Itinerary".
    func shareText(for cart: PackageCart) -> String {
        var lines: [String] = []
        if let name = (cart.packageInfo?.name).nonEmpty { lines.append(name) }
        if let reference = cart.bookingReference.nonEmpty { lines.append("\(bookingIdTitle): \(reference)") }
        lines += summaryRows(for: cart).dropFirst().map { "\($0.label): \($0.value)" }
        for leg in flightLegs(for: cart) {
            let times = [leg.departureTime, leg.arrivalTime].compactMap { $0 }.joined(separator: Constants.dateRangeSeparator)
            lines.append("\(leg.route)\n\(leg.departureLocation) → \(leg.arrivalLocation) \(times)")
        }
        for hotel in hotels(for: cart) {
            let stay = [hotel.checkIn, hotel.checkOut].compactMap { $0 }.joined(separator: Constants.dateRangeSeparator)
            lines.append([hotel.name, stay].filter { !$0.isEmpty }.joined(separator: "\n"))
        }
        return lines.joined(separator: "\n\n")
    }

    // MARK: - Formatting

    private var displayLocale: Locale {
        Locale(identifier: AlmatarStaticPackageSDK.shared.configuration.language.rawValue)
    }

    /// API dates are shown as sent (UTC), without converting to the device time zone.
    private func dateFormatter(template: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = displayLocale
        formatter.timeZone = Constants.utc
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }

    /// e.g. "Thu 16 Jul".
    private var shortDateFormatter: DateFormatter { dateFormatter(template: Constants.shortDateTemplate) }
    /// e.g. "Thu 16 Jul 2026".
    private var fullDateFormatter: DateFormatter { dateFormatter(template: Constants.fullDateTemplate) }

    /// The payment currency, else the SDK's selected currency.
    private func currency(for cart: PackageCart) -> String {
        (cart.payment?.currency).nonEmpty ?? AlmatarStaticPackageSDK.shared.currency
    }

    private func formattedPrice(_ amount: Decimal, currency: String) -> String {
        let value = amount.formatted(
            .number
                .precision(.fractionLength(0...Constants.maxPriceFractionDigits))
                .locale(Constants.priceLocale)
        )
        return "\(currency) \(value)"
    }

    /// "1 visitor" or "n visitors".
    private func visitorsCountText(_ count: Int?) -> String? {
        guard let count, count > 0 else { return nil }
        return count == 1 ? LocalizedKey.oneVisitor.localized() : LocalizedKey.visitorsCount.localized(with: count)
    }

    private func defaultTierTitle(_ refundPercentage: Int) -> String {
        switch refundPercentage {
        case 100...: return LocalizedKey.freeCancellation.localized()
        case ..<1: return LocalizedKey.nonRefundable.localized()
        default: return LocalizedKey.refundPercentage.localized(with: "\(refundPercentage)%")
        }
    }

    private func tierWindow(for policy: CancellationPolicy) -> String? {
        let window = policy.window.nonEmpty
        guard let until = policy.formattedUntil.nonEmpty else { return window }
        let untilText = "\(LocalizedKey.until.localized()) \(until)"
        guard let window else { return untilText }
        return "\(window)\(Constants.separator)\(untilText)"
    }

    /// "Thu 16 Jul – Fri 24 Jul 2026"; the year is shown on the start date only when it differs.
    private func formattedDateRange(from start: String?, to end: String?) -> String? {
        let startDate = parseDate(start)
        let endDate = parseDate(end)
        switch (startDate, endDate) {
        case let (startDate?, endDate?):
            let sameYear = Calendar(identifier: .gregorian).isDate(startDate, equalTo: endDate, toGranularity: .year)
            let startText = (sameYear ? shortDateFormatter : fullDateFormatter).string(from: startDate)
            return startText + Constants.dateRangeSeparator + fullDateFormatter.string(from: endDate)
        case (let date?, nil), (nil, let date?):
            return fullDateFormatter.string(from: date)
        case (nil, nil):
            return nil
        }
    }

    /// "yyyy-MM-dd" from the API as "Thu 16 Jul 2026", or the raw value when it cannot be parsed.
    private func formattedDate(_ value: String?) -> String? {
        guard let value = value.nonEmpty else { return nil }
        guard let date = parseDate(value) else { return value }
        return fullDateFormatter.string(from: date)
    }

    private func parseDate(_ value: String?) -> Date? {
        guard let value = value.nonEmpty else { return nil }
        let parser = DateFormatter()
        parser.locale = Constants.posixLocale
        parser.timeZone = Constants.utc
        parser.dateFormat = Constants.apiDateFormat
        // Accept both "2026-11-18" and "2026-11-18T00:00:00.000Z".
        return parser.date(from: value) ?? parseDateTime(value)
    }

    private func parseDateTime(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }

    /// The wall-clock time exactly as written in the string, e.g. "2026-07-16T08:30:00Z" -> "08:30".
    private func wallClockTime(_ raw: String) -> String? {
        guard let tIndex = raw.firstIndex(of: "T") else { return nil }
        let time = raw[raw.index(after: tIndex)...].prefix(5)
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              parts.allSatisfy({ $0.count == 2 && $0.allSatisfy(\.isNumber) }) else { return nil }
        return String(time)
    }

    /// e.g. "Barcelona (BCN)".
    private func locationText(_ point: FlightPoint) -> String {
        guard let city = point.cityName.nonEmpty ?? point.airportName.nonEmpty else { return point.airportCode }
        return "\(city) (\(point.airportCode))"
    }

    /// "Direct", "1 stop" or "n stops".
    private func stopsText(_ stops: Int?) -> String? {
        guard let stops else { return nil }
        switch stops {
        case ..<1: return LocalizedKey.flightDirect.localized()
        case 1: return LocalizedKey.flightOneStop.localized()
        default: return LocalizedKey.flightStops.localized(with: stops)
        }
    }
}
