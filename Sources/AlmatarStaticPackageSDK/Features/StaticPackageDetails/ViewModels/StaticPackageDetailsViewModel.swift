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

    private enum Constants {
        static let locationIcon = "mappin.and.ellipse"
        static let calendarIcon = "calendar"
        static let separator = " • "
        static let rangeDash = " – "
        static let dayMonthTemplate = "d MMM"
        static let timeFormat = "HH:mm"
        static let apiDateFormat = "yyyy-MM-dd"
        static let posixLocale = Locale(identifier: "en_US_POSIX")
        static let utc = TimeZone(identifier: "UTC")!
    }

    @Published private(set) var state: State = .idle

    /// Product ids of the optional itinerary activities the customer added.
    @Published private(set) var addedActivityIds: Set<Int> = []
    /// `true` while booking or while the host app's payment flow is open.
    @Published private(set) var isStartingPayment = false
    /// Set when payment cannot start or fails; shown as an alert.
    @Published var paymentErrorMessage: String?

    /// State of the "Visitor Details" form; observed directly by its view.
    let visitorForm = VisitorDetailsFormModel()

    // MARK: - Strings
    var goToPaymentTitle: String { LocalizedKey.goToPayment.localized() }
    var journeySnapshotTitle: String { LocalizedKey.journeySnapshot.localized() }
    var retryTitle: String { LocalizedKey.retry.localized() }
    var cancellationPolicyTitle: String { LocalizedKey.cancellationPolicy.localized() }
    private var genericErrorMessage: String { LocalizedKey.genericError.localized() }
    private var dynamicPackageTag: String { LocalizedKey.dynamicPackageTag.localized() }
    private var includedTitle: String { LocalizedKey.itineraryIncluded.localized() }
    private var optionalTitle: String { LocalizedKey.itineraryOptional.localized() }
    private var directFlightTitle: String { LocalizedKey.flightDirect.localized() }

    var packageDetails: PackageDetails? {
        if case .loaded(let details) = state { return details }
        return nil
    }

    private var packageInfo: PackageInfo? { packageDetails?.packageInfo }

    // MARK: - Header

    var headerTitle: String {
        packageInfo?.name ?? ""
    }

    var headerTags: [String] {
        var tags: [String] = []
        if let duration = packageInfo?.duration.nonEmpty {
            tags.append(duration)
        }
        return tags
    }

    /// Remote images for the header carousel; empty falls back to the bundled assets.
    var headerImageURLs: [URL] {
        (packageInfo?.images ?? []).compactMap { Optional($0).nonEmpty.flatMap(URL.init(string:)) }
    }
    
    // MARK: - Sections

    var journeySnapshotItems: [JourneySnapshotItem] {
        packageInfo?.journeySnapshot ?? []
    }

    var parkHighlightsTitle: String {
        packageInfo?.highlights?.title.nonEmpty ?? ""
    }

    var parkHighlightItems: [ParkHighlightItem] {
        packageInfo?.highlights?.items ?? []
    }

    var packageScheduleTitle: String {
        packageInfo?.products?.title.nonEmpty ?? ""
    }

    var packageScheduleSubtitle: String? {
        packageInfo?.products?.subtitle.nonEmpty
    }

    var packageScheduleItems: [PackageScheduleItem] {
        let products = packageInfo?.products?.items ?? []
        return products.enumerated().map { index, product in scheduleItem(product, index: index) }
    }

    var itineraryDays: [ItineraryDay] {
        packageInfo?.itinerary?.days ?? []
    }

    var itineraryDownloadURL: URL? {
        packageInfo?.itinerary?.downloadUrl.nonEmpty.flatMap(URL.init(string:))
    }

    var itineraryStrings: ItineraryStrings {
        let itinerary = packageInfo?.itinerary
        return ItineraryStrings(
            title: itinerary?.title.nonEmpty ?? LocalizedKey.itinerary.localized(),
            subtitle: itinerary?.subtitle.nonEmpty ?? LocalizedKey.itinerarySubtitle.localized(),
            activities: LocalizedKey.itineraryActivities.localized(),
            included: includedTitle,
            add: LocalizedKey.itineraryAdd.localized(),
            added: LocalizedKey.itineraryAdded.localized(),
            download: LocalizedKey.itineraryDownload.localized(),
            readMore: LocalizedKey.readMore.localized(),
            readLess: LocalizedKey.readLess.localized(),
            dayLabel: { String(format: LocalizedKey.itineraryDay.localized(), $0) }
        )
    }

    var includedServicesTitle: String {
        packageInfo?.includedServices?.title.nonEmpty ?? ""
    }

    var includedServicesSubtitle: String {
        packageInfo?.includedServices?.description.nonEmpty ?? ""
    }

    var includedInYourPassTitle: String {
        packageInfo?.includedServices?.subtitle.nonEmpty ?? ""
    }

    var includedServiceItems: [IncludedServiceItem] {
        packageInfo?.includedServices?.items ?? []
    }

    /// Tiers in the order returned by the API (earliest cancellation window first).
    var cancellationTiers: [CancellationPolicyTier] {
        let policies = packageInfo?.cancellationPolicies ?? []
        return policies.enumerated().map { index, policy in
            return CancellationPolicyTier(
                id: index,
                title: policy.title.nonEmpty ?? "",
                window: "\(policy.window.nonEmpty ?? "") \(LocalizedKey.until.localized()) \(policy.until.nonEmpty ?? "")",
                note: policy.note.nonEmpty
            )
        }
    }

    // MARK: - Init

    typealias PaymentResult = AlmatarStaticPackageSDK.PaymentResult

    private let packageId: String
    /// Cart from `POST v1/packages/book`; created on "Go to payment" when missing.
    private var cartId: String
    private let repository: StaticPackagesRepositoryProtocol
    private let startPayment: (PackagePaymentRequest) async -> PaymentResult
    private let onPaymentFinished: () -> Void

    init(
        packageId: String,
        cartId: String,
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
            let details = try await repository.fetchPackageDetails(cartId: cartId)
            visitorForm.configure(with: details.dynamicForm)
            state = .loaded(details)
        } catch is CancellationError {
            state = .idle
        } catch {
            let apiMessages = (error as? NetworkError)?.apiMessages ?? []
            state = .failed(message: apiMessages.isEmpty ? genericErrorMessage : apiMessages.joined(separator: "\n"))
        }
    }

    var okTitle: String { LocalizedKey.ok.localized() }

    // MARK: - Total price

    /// e.g. "Total price • 2 visitors".
    func totalPriceLabel(visitorCount: Int) -> String {
        visitorCount == 1
            ? LocalizedKey.totalPriceOneVisitor.localized()
            : LocalizedKey.totalPriceVisitors.localized(with: visitorCount)
    }

    // MARK: - Price breakdown
    var priceDetailsTitle: String { LocalizedKey.priceDetails.localized() }
    var priceIncludedTitle: String { LocalizedKey.itineraryIncluded.localized() }

    /// Sections of the cart price that have something to show.
    var priceBreakdownSections: [PriceBreakdownSection] {
        (packageDetails?.price?.breakdown ?? []).filter { section in
            !(section.items ?? []).isEmpty || section.amount != nil
        }
    }

    /// e.g. "6,000"; `nil` until the price is loaded.
    var totalPriceAmountText: String? {
        let price = packageDetails?.price.map { $0.finalAmount }
       return CurrencyManager.shared.formatPrice(value: price)
    }

    /// Package price plus the optional itinerary activities the customer added, in SAR.
    var paymentAmount: Double? {
        guard let details = packageDetails else { return nil }
        return details.price?.finalAmount ?? 0.0
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
                amountInSar: Float(amount),
                productType: PackagePaymentRequest.productType,
                cancellationTiers: cancellationTiers.isEmpty ? nil : cancellationTiers
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
        var parts = [activity.isOptional ? optionalTitle : includedTitle]
        if let duration = activity.duration.nonEmpty {
            parts.append(duration)
        }
        if activity.isOptional, let price = activity.price {
            parts.append("+ \(price.currency) \(Self.formattedAmount(price.amount))")
        }
        return parts.joined(separator: Constants.separator)
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

    // MARK: - Products → schedule steps

    private func scheduleItem(_ product: PackageProduct, index: Int) -> PackageScheduleItem {
        let status = product.isMandatory ? includedTitle : optionalTitle
        let tag = product.tags?.first.map { PackageScheduleTag(icon: $0.icon, title: $0.label) }
        return PackageScheduleItem(
            id: "\(index)-\(product.productType.rawValue)",
            title: product.title,
            description: nil,
            tag: product.productType != .addon ? tag : nil,
            statusLabel: nil,
            card: scheduleCard(product, status: status)
        )
    }

    private func scheduleCard(_ product: PackageProduct, status: String) -> PackageScheduleCard? {
        switch product.productType {
        case .flight:
            guard let flightInfo = product.flightInfo, !flightInfo.legs.isEmpty else { return nil }
            return PackageScheduleCard(
                imageUrl: nil,
                title: product.title,
                rating: nil,
                details: nil,
                description: nil,
                room: nil,
                statusLabel: nil,
                flight: PackageScheduleFlight(
                    legs: flightInfo.legs.map(flightLeg),
                    isUpgradeAvailable: flightInfo.isCabinUpgradeAvailable == true
                )
            )
        case .hotel:
            guard let hotel = product.hotelInfo else { return nil }
            return PackageScheduleCard(
                imageUrl: hotel.imageUrl,
                title: product.title,
                rating: hotel.starRating,
                details: hotelDetails(hotel),
                description: nil,
                room: hotel.room.map { roomInfo($0) },
                statusLabel: status
            )
        case .addon:
            guard let addon = product.addonInfo else { return nil }
            return PackageScheduleCard(
                imageUrl: addon.image,
                title: addon.title,
                rating: nil,
                details: nil,
                description: addon.description,
                room: nil,
                statusLabel: status
            )
        case .unknown:
            return nil
        }
    }

    private func flightLeg(_ leg: FlightLeg) -> PackageScheduleFlightLeg {
        let subtitle = [leg.flightNumber.nonEmpty, leg.cabin.nonEmpty].compactMap { $0 }
        let durationInfo = [leg.duration.nonEmpty, stopsText(leg.stops)].compactMap { $0 }
        return PackageScheduleFlightLeg(
            // TODO: Map once the API returns the upgraded cabin state per leg.
            isUpgraded: false,
            airlineLogoUrl: leg.airline?.logoUrl,
            route: LocalizedKey.flightRoute.localized(with: cityName(leg.departure), cityName(leg.arrival)),
            subtitle: subtitle.isEmpty ? nil : subtitle.joined(separator: Constants.separator),
            departureTime: formatShortDate(leg.departure.time),
            departureLocation: locationText(leg.departure),
            arrivalTime: formatShortDate(leg.arrival.time),
            arrivalLocation: locationText(leg.arrival),
            durationInfo: durationInfo.isEmpty ? nil : durationInfo.joined(separator: Constants.separator)
        )
    }

    /// Returns the wall-clock time exactly as written in the string, ignoring any timezone suffix.
    /// e.g. "2026-12-10T07:30:00.000Z" -> "07:30" regardless of the device timezone.
    private func formatShortDate(_ raw: String?) -> String {
        guard let raw, let tIndex = raw.firstIndex(of: "T") else { return "" }
        let time = raw[raw.index(after: tIndex)...].prefix(5)
        let parts = time.split(separator: ":")
        guard parts.count == 2,
              parts.allSatisfy({ $0.count == 2 && $0.allSatisfy(\.isNumber) }) else { return "" }
        return String(time)
    }
    
    /// City name, falling back to the airport code.
    private func cityName(_ point: FlightPoint) -> String {
        point.cityName.nonEmpty ?? point.airportCode
    }

    /// e.g. "Barcelona (BCN)".
    private func locationText(_ point: FlightPoint) -> String {
        guard let city = point.cityName.nonEmpty ?? point.airportName.nonEmpty else { return point.airportCode }
        return "\(city) (\(point.airportCode))"
    }

    /// "Direct", "1 stop" or "2 stops".
    private func stopsText(_ stops: Int?) -> String? {
        guard let stops else { return nil }
        switch stops {
        case ..<1: return directFlightTitle
        case 1: return LocalizedKey.flightOneStop.localized()
        default: return LocalizedKey.flightStops.localized(with: stops)
        }
    }

    /// Location line ("Palace-style luxury • Riyadh") and stay line ("16 Jul – 21 Jul • 5 Nights").
    private func hotelDetails(_ hotel: HotelInfo) -> [PackageScheduleInfo] {
        var details: [PackageScheduleInfo] = []

        let location = [hotel.tagline.nonEmpty, hotel.city.nonEmpty].compactMap { $0 }
        if !location.isEmpty {
            details.append(PackageScheduleInfo(icon: Constants.locationIcon, text: location.joined(separator: Constants.separator)))
        }

        var stay: [String] = []
        let checkIn = Self.parseDate(hotel.checkIn)
        let checkOut = Self.parseDate(hotel.checkOut)
        switch (checkIn, checkOut) {
        case let (checkIn?, checkOut?):
            stay.append(dayMonthFormatter.string(from: checkIn) + Constants.rangeDash + dayMonthFormatter.string(from: checkOut))
        case (let date?, nil), (nil, let date?):
            stay.append(dayMonthFormatter.string(from: date))
        case (nil, nil):
            break
        }
        if let nights = hotel.nights, nights > 0 {
            stay.append(LocalizedKey.nightsTag.localized(with: nights))
        }
        if !stay.isEmpty {
            details.append(PackageScheduleInfo(icon: Constants.calendarIcon, text: stay.joined(separator: Constants.separator)))
        }
        return details
    }

    /// e.g. "Room • Deluxe City View" / "1 king bed • sleeps 2".
    private func roomInfo(_ room: HotelRoom) -> PackageScheduleRoom {
        var subtitle: [String] = []
        if let beds = room.beds.nonEmpty {
            subtitle.append(beds)
        }
        if let sleeps = room.sleeps, sleeps > 0 {
            subtitle.append(LocalizedKey.hotelSleeps.localized(with: sleeps))
        }
        return PackageScheduleRoom(
            title: LocalizedKey.hotelRoom.localized(with: room.name),
            subtitle: subtitle.isEmpty ? nil : subtitle.joined(separator: Constants.separator)
        )
    }

    // MARK: - Formatting

    private var displayLocale: Locale {
        Locale(identifier: AlmatarStaticPackageSDK.shared.configuration.language.rawValue)
    }

    /// API times are shown as sent (UTC), without converting to the device time zone.
    private var dayMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = displayLocale
        formatter.timeZone = Constants.utc
        formatter.setLocalizedDateFormatFromTemplate(Constants.dayMonthTemplate)
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = displayLocale
        formatter.timeZone = Constants.utc
        formatter.dateFormat = Constants.timeFormat
        return formatter
    }

    private static func formattedAmount(_ amount: Double) -> String {
        CurrencyManager.shared.formatPrice(value: amount)
    }
    
    private static func parseDateTime(_ value: String) -> Date? {
          let formatter = ISO8601DateFormatter()
          if let date = formatter.date(from: value) { return date }
          formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
          return formatter.date(from: value)
      }

      private static func parseDate(_ value: String?) -> Date? {
          guard let value = value.nonEmpty else { return nil }
          let formatter = DateFormatter()
          formatter.locale = Constants.posixLocale
          formatter.timeZone = Constants.utc
          formatter.dateFormat = Constants.apiDateFormat
          return formatter.date(from: value)
      }
}

extension String {
    func getAsDate(_ format: String = "MMM dd yyyy hh:mma", inGMT: Bool = false ) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        if inGMT {
            dateFormatter.timeZone = TimeZone(identifier: "GMT")
        }
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.calendar = Calendar(identifier: .gregorian)
        let date = dateFormatter.date(from: self)
        return  date
    }
}

extension Date {
    func stringValue(_ format: String = "yyyy-MM-dd", inGMT: Bool = false) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en")
        dateFormatter.dateFormat = format
        if inGMT {
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
        }
        return dateFormatter.string(from: self)
    }
}
