//
//  StaticPackageDetailsViewModel.swift
//  AlmatarStaticPackageSDK
//

import Foundation
import Combine

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
        /// Waits for the traveller counter to settle so repeated taps send one request.
        static let travellerSyncDelay: RunLoop.SchedulerTimeType.Stride = .milliseconds(400)
    }

    @Published private(set) var state: State = .idle

    /// Product ids of the optional itinerary activities the customer added.
    @Published private(set) var addedActivityIds: Set<Int> = []
    /// `true` while booking or while the host app's payment flow is open.
    @Published private(set) var isStartingPayment = false
    /// Set when payment cannot start or fails, or the cart cannot be updated; shown as an alert.
    @Published var paymentErrorMessage: String?
    /// Number of cart allocations in flight; see `isUpdatingCart`.
    @Published private var pendingAllocations = 0

    /// `true` while the cart is re-priced after a traveller or option change.
    var isUpdatingCart: Bool { pendingAllocations > 0 }

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
    /// Order from `POST v1/packages/orders`, created on "Go to payment" once the details are valid.
    private(set) var order: PackageOrder?
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
        observeTravellerCounts()
    }

    func loadPackageDetails() async {
        state = .loading
        do {
            let details = try await repository.fetchPackageDetails(cartId: cartId)
            visitorForm.configure(with: details.dynamicForm)
            // The form starts with the travellers the cart is priced for.
            if let travellers = details.travellers {
                visitorForm.setTravellerCounts(Self.cartTravellerCounts(travellers))
            }
            allocatedCounts = currentTravellerCounts
            requestedCounts = currentTravellerCounts
            cartNeedsReload = false
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

    /// e.g. "6,000"; the cart total, which already includes the allocated travellers and options.
    /// `nil` until the price is loaded.
    func totalPriceAmountText(visitorCount: Int) -> String? {
        guard let price = packageDetails?.price else { return nil }
        return CurrencyManager.shared.formatPrice(value: price.finalAmount, currencyCode: price.currency)
    }

    /// e.g. "+ 1,680 SAR • Cabin upgrade"; `nil` when no paid option is chosen.
    func optionsDetailText(visitorCount: Int) -> String? {
        let amount = optionsAmount(visitorCount: visitorCount)
        guard amount > 0 else { return nil }
        let titles = selectedProductOptions.keys.sorted().compactMap { optionsSection(forProductAt: $0)?.title.nonEmpty }
        let label = titles.isEmpty ? LocalizedKey.selectOptions.localized() : titles.joined(separator: ", ")
        return "+ \(CurrencyManager.shared.formatPrice(value: amount, currencyCode: packageDetails?.price?.currency)) • \(label)"
    }

    // MARK: - Product options

    /// The product whose options screen is open, by its index in the products list.
    @Published var optionsProductIndex: Int?

    /// The option chosen for each product, by product index.
    @Published private(set) var selectedProductOptions: [Int: ProductOption] = [:]

    /// Chosen options cost per visitor, for the whole group.
    func optionsAmount(visitorCount: Int) -> Double {
        selectedProductOptions.values.reduce(0) { $0 + ($1.price ?? 0) } * Double(visitorCount)
    }

    func optionsSection(forProductAt index: Int) -> ProductOptionsSection? {
        guard let products = packageInfo?.products?.items, products.indices.contains(index) else { return nil }
        return products[index].optionsSection
    }

    /// Opens the options of the product shown by a schedule step, e.g. the flight's cabin class.
    func changeUpgradeTapped(_ item: PackageScheduleItem) {
        // Step ids are "<product index>-<type>".
        guard let index = item.id.split(separator: "-").first.flatMap({ Int($0) }),
              optionsSection(forProductAt: index) != nil else { return }
        optionsProductIndex = index
    }

    func makeProductOptionsViewModel(productIndex: Int) -> ProductOptionsViewModel? {
        guard let section = optionsSection(forProductAt: productIndex) else { return nil }
        return ProductOptionsViewModel(
            section: section,
            selectedOption: selectedProductOptions[productIndex],
            visitorForm: visitorForm,
            cartPrice: packageDetails?.price,
            allocateOption: { [weak self] option in
                guard let self else { return nil }
                return await self.allocateOption(option, productIndex: productIndex)
            },
            currentCartPrice: { [weak self] in self?.packageDetails?.price }
        )
    }

    /// The cart total; travellers and options are priced by the cart allocation.
    var paymentAmount: Double? {
        guard let details = packageDetails else { return nil }
        return details.price?.finalAmount ?? 0.0
    }

    /// Validates the visitors' details, creates the order, books the package, then opens the host app's payment flow.
    func goToPaymentTapped() async {
        guard !isStartingPayment, paymentAmount != nil else { return }
        isStartingPayment = true
        defer { isStartingPayment = false }

        // Pay the price of the group shown on screen: send any traveller change still waiting.
        syncTravellerCounts()
        _ = await allocationTask?.value
        guard allocatedCounts == currentTravellerCounts, let amount = paymentAmount else { return }

        do {
            guard try await validateVisitorDetails() else {
                // Show the field errors in the form along with the alert.
                visitorForm.shouldValidate = true
                paymentErrorMessage = genericErrorMessage
                return
            }
            order = try await repository.createOrder(cartId: cartId)
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

    /// Calls `POST v1/packages/validate-info` with the visitors form; `true` when the details are accepted.
    private func validateVisitorDetails() async throws -> Bool {
        let request = ValidateInfoRequest(cartId: cartId, sections: visitorForm.validateInfoSections)
        return try await repository.validateInfo(request: request)
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

    // MARK: - Cart allocation

    /// Traveller counts the cart is currently priced for.
    private var allocatedCounts: [VisitorDetailsFormModel.Traveller: Int] = [:]
    /// Traveller counts of the group when they were last sent to the cart.
    private var requestedCounts: [VisitorDetailsFormModel.Traveller: Int] = [:]
    /// The last queued allocation; allocations run one after another, in the order they were made.
    private var allocationTask: Task<Bool, Never>?
    /// Allocations queued or running; the cart's travellers are applied when it drops to zero.
    private var queuedAllocations = 0
    /// `true` when an allocation succeeded but the cart could not be reloaded, so `packageDetails` is out of date.
    private var cartNeedsReload = false
    private var cancellables = Set<AnyCancellable>()

    private var currentTravellerCounts: [VisitorDetailsFormModel.Traveller: Int] {
        Self.travellerCounts(visitorForm.visitors)
    }

    nonisolated private static func cartTravellerCounts(_ travellers: CartTravellers) -> [VisitorDetailsFormModel.Traveller: Int] {
        [.adults: travellers.adults ?? 0, .children: travellers.children ?? 0, .infants: travellers.infants ?? 0]
    }

    nonisolated private static func travellerCounts(_ visitors: [VisitorDetailsFormModel.Visitor]) -> [VisitorDetailsFormModel.Traveller: Int] {
        Dictionary(uniqueKeysWithValues: VisitorDetailsFormModel.Traveller.allCases.map { traveller in
            (traveller, visitors.filter { $0.type == traveller }.count)
        })
    }

    /// Re-prices the cart whenever the group changes, from the counters or "Remove visitor".
    private func observeTravellerCounts() {
        visitorForm.$visitors
            .map(Self.travellerCounts)
            .removeDuplicates()
            .debounce(for: Constants.travellerSyncDelay, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { @MainActor in self?.syncTravellerCounts() }
            }
            .store(in: &cancellables)
    }

    /// Sends one allocation per traveller type whose count differs from the cart,
    /// e.g. removing an adult can also remove an infant.
    private func syncTravellerCounts() {
        guard packageDetails != nil else { return }
        requestedCounts = currentTravellerCounts
        for traveller in VisitorDetailsFormModel.Traveller.allCases {
            enqueueAllocation { viewModel in
                let quantity = viewModel.visitorForm.count(traveller)
                guard viewModel.allocatedCounts[traveller] != quantity else { return true }
                let request = CartAllocationRequest.traveller(
                    packageId: viewModel.packageId,
                    type: traveller.allocationType,
                    quantity: quantity
                )
                guard await viewModel.allocate(request) else { return false }
                viewModel.allocatedCounts[traveller] = quantity
                return true
            }
        }
    }

    /// Allocates an option picked on the options screen, after any allocation already queued,
    /// then reloads the cart. Returns the error message when the cart could not be updated, else `nil`.
    private func allocateOption(_ option: ProductOption?, productIndex: Int) async -> String? {
        guard let productId = packageInfo?.products?.items?[safe: productIndex]?.productId?.value else {
            return genericErrorMessage
        }
        let request = CartAllocationRequest.option(
            packageId: packageId,
            productId: productId,
            optionId: option?.optionId?.value
        )
        let succeeded = await enqueueAllocation { viewModel in
            guard await viewModel.allocate(request) else { return false }
            viewModel.selectedProductOptions[productIndex] = option
            return true
        }.value
        guard !succeeded else { return nil }
        // The options screen shows the error itself, not this screen's alert behind it.
        let message = paymentErrorMessage ?? genericErrorMessage
        paymentErrorMessage = nil
        return message
    }

    /// Runs the operation after every allocation already queued; its result says whether the cart was updated.
    @discardableResult
    private func enqueueAllocation(_ operation: @escaping @MainActor (StaticPackageDetailsViewModel) async -> Bool) -> Task<Bool, Never> {
        let previous = allocationTask
        queuedAllocations += 1
        let task = Task { [weak self] () -> Bool in
            _ = await previous?.value
            guard let self else { return false }
            let succeeded = await operation(self)
            self.queuedAllocations -= 1
            if self.queuedAllocations == 0 {
                self.applyCartTravellers()
            }
            return succeeded
        }
        allocationTask = task
        return task
    }

    /// Once every queued allocation is done, takes the traveller counts from the reloaded cart:
    /// they become the allocated counts, and the visitors form is updated to match them
    /// unless the user changed the group again since it was sent (that change is synced next).
    private func applyCartTravellers() {
        guard !cartNeedsReload, let travellers = packageDetails?.travellers else { return }
        let cartCounts = Self.cartTravellerCounts(travellers)
        allocatedCounts = cartCounts
        guard currentTravellerCounts == requestedCounts, currentTravellerCounts != cartCounts else { return }
        visitorForm.setTravellerCounts(cartCounts)
        requestedCounts = currentTravellerCounts
    }

    /// Calls `POST carts/{cartId}/allocate`, then reloads the cart (`GET carts/{cartId}`) to refresh the screen.
    /// Returns `false` and shows the error when the cart could not be updated.
    private func allocate(_ request: CartAllocationRequest) async -> Bool {
        pendingAllocations += 1
        defer { pendingAllocations -= 1 }
        do {
            // The allocation response is not used; the screen shows the cart reloaded from the API.
            _ = try await repository.allocateCart(cartId: cartId, request: request)
            await reloadCart()
            return true
        } catch is CancellationError {
            return false
        } catch {
            let apiMessages = (error as? NetworkError)?.apiMessages ?? []
            paymentErrorMessage = apiMessages.isEmpty ? genericErrorMessage : apiMessages.joined(separator: "\n")
            return false
        }
    }

    /// Shows the cart as read from `GET carts/{cartId}` after an allocation.
    /// The visitors form is not reconfigured, so the group and entered details stay as filled in.
    /// If the reload fails, the current screen stays and the error is shown.
    private func reloadCart() async {
        do {
            let details = try await repository.fetchPackageDetails(cartId: cartId)
            cartId = details.cartId
            cartNeedsReload = false
            state = .loaded(details)
        } catch is CancellationError {
            cartNeedsReload = true
        } catch {
            cartNeedsReload = true
            let apiMessages = (error as? NetworkError)?.apiMessages ?? []
            paymentErrorMessage = apiMessages.isEmpty ? genericErrorMessage : apiMessages.joined(separator: "\n")
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
                    isUpgradeAvailable: !(product.optionsSection?.options ?? []).isEmpty,
                    upgradeTitle: product.optionsSection?.ctaText.nonEmpty
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
                title: addon.title ?? "",
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

private extension VisitorDetailsFormModel.Traveller {
    /// Traveller `type` in the allocate request.
    var allocationType: String {
        switch self {
        case .adults: return "adult"
        case .children: return "child"
        case .infants: return "infant"
        }
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
