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
        static let flightIcon = "airplane"
        static let locationIcon = "mappin.and.ellipse"
        static let calendarIcon = "calendar"
        static let separator = " • "
        static let routeArrow = " → "
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

    // MARK: - Strings
    var goToPaymentTitle: String { LocalizedKey.goToPayment.localized() }
    var journeySnapshotTitle: String { LocalizedKey.journeySnapshot.localized() }
    var retryTitle: String { LocalizedKey.retry.localized() }
    var cancellationPolicyTitle: String { LocalizedKey.cancellationPolicy.localized() }
    private var genericErrorMessage: String { LocalizedKey.genericError.localized() }
    private var dynamicPackageTag: String { LocalizedKey.dynamicPackageTag.localized() }
    private var includedTitle: String { LocalizedKey.itineraryIncluded.localized() }
    private var optionalTitle: String { LocalizedKey.itineraryOptional.localized() }

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
        var tags = [dynamicPackageTag]
        if let duration = packageInfo?.duration.nonEmpty {
            tags.append(duration)
        }
        return tags
    }

    /// Remote images for the header carousel; empty falls back to the bundled assets.
    var headerImageURLs: [URL] {
        (packageInfo?.images ?? []).compactMap { Optional($0).nonEmpty.flatMap(URL.init(string:)) }
    }

    /// Asset names for the header carousel (`Assets.xcassets`), used when the API has no images.
    var headerImageNames: [String] { PackageAsset.carouselImageNames }

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

    private let cartId: String
    private let repository: StaticPackagesRepositoryProtocol
    private let onGoToPayment: () -> Void

    init(
        cartId: String,
        repository: StaticPackagesRepositoryProtocol,
        onGoToPayment: @escaping () -> Void
    ) {
        self.cartId = cartId
        self.repository = repository
        self.onGoToPayment = onGoToPayment
    }

    func loadPackageDetails() async {
        state = .loading
        do {
            let details = try await repository.fetchPackageDetails(cartId: cartId)
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
            description: product.description,
            tag: tag,
            statusLabel: status,
            card: scheduleCard(product, status: status)
        )
    }

    private func scheduleCard(_ product: PackageProduct, status: String) -> PackageScheduleCard? {
        switch product.productType {
        case .flight:
            guard let legs = product.flightInfo?.legs, !legs.isEmpty else { return nil }
            return PackageScheduleCard(
                imageUrl: nil,
                title: product.title,
                rating: nil,
                details: legs.map { PackageScheduleInfo(icon: Constants.flightIcon, text: flightLegText($0)) },
                description: nil,
                room: nil,
                statusLabel: status
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

    /// e.g. "SV-1430 • JED → RUH • 16 Jul • 08:30 – 10:15".
    private func flightLegText(_ leg: FlightLeg) -> String {
        var parts: [String] = []
        if let flightNumber = leg.flightNumber.nonEmpty {
            parts.append(flightNumber)
        }
        parts.append(leg.departure.airportCode + Constants.routeArrow + leg.arrival.airportCode)

        if let departure = Self.parseDateTime(leg.departure.time) {
            parts.append(dayMonthFormatter.string(from: departure))
            var times = timeFormatter.string(from: departure)
            if let arrival = Self.parseDateTime(leg.arrival.time) {
                times += Constants.rangeDash + timeFormatter.string(from: arrival)
            }
            parts.append(times)
        }
        return parts.joined(separator: Constants.separator)
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

    private static func parseDateTime(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value)
    }

    /// Parses "yyyy-MM-dd".
    private static func parseDate(_ value: String?) -> Date? {
        guard let value = value.nonEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Constants.posixLocale
        formatter.timeZone = Constants.utc
        formatter.dateFormat = Constants.apiDateFormat
        return formatter.date(from: value)
    }

    private static func formattedAmount(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount)"
    }
}
