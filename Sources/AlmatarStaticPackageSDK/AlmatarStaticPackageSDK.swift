//
//  AlmatarStaticPackageSDK.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI

/// Public entry point of the Static Packages SDK.
/// The host app must call `configure(_:)` before using any SDK feature.
@MainActor
public final class AlmatarStaticPackageSDK {
    public static let shared = AlmatarStaticPackageSDK()

    public private(set) var configuration = StaticPackageConfiguration(baseURL: "")

    /// `true` once a non-empty base URL has been provided.
    public var isConfigured: Bool { !configuration.baseURL.isEmpty }

    /// Called when the package flow should be closed (e.g. the user taps close/back on the first screen).
    /// The host app is responsible for dismissing the presented flow.
    public var onDismiss: (() -> Void)?

    /// Runs the host app's payment flow when the user taps "Go to payment".
    /// Held weakly, so the host app must keep a strong reference to it.
    public weak var delegate: AlmatarStaticPackageSDKProtocol?

    /// Called when the user taps "Go to My Trips" on the booking confirmation screen.
    /// When the SDK presented the confirmation, it is closed first, so the host app can navigate right away.
    public var onGoToMyTrips: (() -> Void)?

    /// Called when the user taps "Back to Home" on the booking confirmation screen.
    /// When the SDK presented the confirmation, it is closed first, so the host app can navigate right away.
    public var onBackToHome: (() -> Void)?

    /// Called with the order id when the user taps "Receipt" on the booking confirmation screen.
    /// The button is hidden while this is `nil`.
    public var onViewReceipt: ((_ orderId: String) -> Void)?

    /// The booking confirmation the SDK presented after payment, while it is on screen.
    private weak var confirmationController: UIViewController?

    private init() {}

    // MARK: - Configuration

    public func configure(_ configuration: StaticPackageConfiguration) {
        self.configuration = configuration
        syncNetworkClient()
    }

    public func setBaseURL(_ baseURL: String) {
        configuration.baseURL = baseURL
    }

    public func setLanguage(_ language: AppLanguage) {
        configuration.language = language
        syncNetworkClient()
    }

    /// Where the SDK loads its data from: the backend or the bundled mock JSON.
    /// Starts from `StaticPackageConfiguration.useMockData`.
    public var dataSource: StaticPackageDataSource { configuration.useMockData ? .mock : .remote }

    /// Switches between the backend (`.remote`) and the bundled mock JSON (`.mock`).
    /// Applies to every request made after the call, including screens opened afterwards.
    public func setDataSource(_ dataSource: StaticPackageDataSource) {
        configuration.useMockData = dataSource == .mock
    }

    /// The bundled mock response the SDK serves for an endpoint in mock mode, as raw JSON.
    /// For host apps that call a package endpoint themselves (e.g. My Trips calling
    /// `api/v1/packages/orders`) and want the same mock data when `dataSource == .mock`.
    /// - Parameter path: The endpoint path, e.g. `"api/v1/packages/orders"`, or a full URL.
    ///   The host, a leading `/` and any query string are ignored.
    /// - Returns: The JSON, or `nil` when the SDK has no mock for that path.
    public func mockResponseData(forPath path: String) -> Data? {
        MockURLProtocol.mockData(forPath: path)
    }

    // MARK: - Currency

    /// The user's selected currency code, e.g. "SAR".
    public var currency: String { configuration.currency }

    /// The currencies provided by the host app, base currency first.
    public var availableCurrencies: [StaticPackageCurrency] { configuration.availableCurrencies }

    /// The selected currency's details, when it is in `availableCurrencies`.
    public var currentCurrency: StaticPackageCurrency? {
        availableCurrencies.first { $0.code.caseInsensitiveCompare(configuration.currency) == .orderedSame }
    }

    /// Call when the user changes currency in the host app.
    public func setCurrency(_ code: String) {
        configuration.currency = code
    }

    /// Call when the host app loads or refreshes its currency list and rates.
    public func setAvailableCurrencies(_ currencies: [StaticPackageCurrency]) {
        configuration.availableCurrencies = currencies
    }

    // MARK: - Request Providers

    /// Provides the access token sent as `Authorization: Bearer <token>`.
    /// Called before every request; return `nil` for guest users.
    public func setTokenProvider(_ provider: TokenProvider?) {
        NetworkClient.shared.setTokenProvider(provider)
    }

    /// Provides extra headers merged into every request.
    /// They override SDK default headers with the same name.
    public func setHeadersProvider(_ provider: HeadersProvider?) {
        NetworkClient.shared.setHeadersProvider(provider)
    }

    // MARK: - Views

    /// Returns the Static Package Details screen for the given package, in the configured language.
    /// - Parameters:
    ///   - packageId: The package to show.
    ///   - cartId: The cart from `POST v1/packages/book`, if the package was already booked.
    ///     When `nil`, the package is booked when the user taps "Go to payment".
    public func getStaticPackageDetailsView(packageId: String, cartId: String) -> some View {
        let viewModel = StaticPackageDetailsViewModel(
            packageId: packageId,
            cartId: cartId,
            repository: makeStaticPackagesRepository(),
            startPayment: { [weak self] request in
                guard let self else { return .failure(.validation(message: "")) }
                return await self.startPayment(request)
            },
            onPaymentFinished: { [weak self] orderId in
                self?.presentPackageBookingConfirmation(id: orderId)
            }
        )
        return StaticPackageDetailsView(viewModel: viewModel)
            .environment(\.layoutDirection, configuration.language.layoutDirection)
    }
    /// Returns the Package Booking Confirmation screen for the given order, in the configured language,
    /// for host apps that show it themselves. The buttons call `onGoToMyTrips` / `onBackToHome` directly.
    public func getPackageBookingConfirmationView(id: String) -> some View {
        makeBookingConfirmationView(
            id: id,
            onGoToMyTrips: { [weak self] in self?.onGoToMyTrips?() },
            onBackToHome: { [weak self] in self?.onBackToHome?() }
        )
    }

    /// Presents the Package Booking Confirmation full screen on top of everything (navigation bars,
    /// sheets and the package screens). "Go to My Trips" and "Back to Home" close it,
    /// then call `onGoToMyTrips` / `onBackToHome`.
    public func presentPackageBookingConfirmation(id: String) {
        let view = makeBookingConfirmationView(
            id: id,
            onGoToMyTrips: { [weak self] in
                self?.closeBookingConfirmation { self?.onGoToMyTrips?() }
            },
            onBackToHome: { [weak self] in
                self?.closeBookingConfirmation { self?.onBackToHome?() }
            }
        )
        confirmationController = TopViewControllerPresenter.present(view)
    }

    private func closeBookingConfirmation(then action: @escaping () -> Void) {
        TopViewControllerPresenter.dismiss(confirmationController, completion: action)
        confirmationController = nil
    }

    func makeBookingConfirmationView(
        id: String,
        onGoToMyTrips: @escaping () -> Void,
        onBackToHome: @escaping () -> Void
    ) -> some View {
        let viewModel = PackageBookingConfimrationViewModel(
            id: id,
            repository: makeStaticPackagesRepository(),
            onGoToMyTrips: onGoToMyTrips,
            onBackToHome: onBackToHome,
            onViewReceipt: onViewReceipt == nil ? nil : { [weak self] orderId in self?.onViewReceipt?(orderId) }
        )
        return PackageBookingConfimrationView(viewModel: viewModel)
            .environment(\.layoutDirection, configuration.language.layoutDirection)
    }
    
    /// Returns the list of package cards for a section provided by the host app.
    /// "Book" creates a cart for the package, then pushes its details screen,
    /// so the view must be shown inside a `NavigationStack`.
    /// - Parameter section: The title and packages to show, e.g. decoded from the host app's API.
    public func getPackagesListView(section: PackagesSection) -> some View {
        PackagesListView(section: section)
            .environment(\.layoutDirection, configuration.language.layoutDirection)
    }

    // MARK: - My Trips

    /// Fetches one page of the user's package bookings (`GET api/v1/packages/orders`),
    /// for host apps that merge package trips into their own My Trips list.
    /// - Parameters:
    ///   - timeframe: Upcoming or previous bookings.
    ///   - offset: Number of trips already loaded.
    ///   - limit: Page size.
    ///   - years: For previous bookings only, the booking years to filter by.
    /// Throws when the SDK is not configured, the request fails, or the response cannot be decoded.
    public func fetchPackageTrips(
        timeframe: PackageTripTimeframe,
        offset: Int = 0,
        limit: Int = 10,
        years: [Int]? = nil
    ) async throws -> PackageTripsPage {
        try await makeStaticPackagesRepository().fetchPackageTrips(
            timeframe: timeframe, offset: offset, limit: limit, years: years
        )
    }

    /// Returns the package My Trips screen: Upcoming / Past tabs with the user's bookings.
    /// Tapping a trip pushes its booking confirmation, so the view must be shown inside a `NavigationStack`.
    /// The back button uses the shared SDK toolbar and dismisses the screen.
    public func getPackageTripsView() -> some View {
        let repository = makeStaticPackagesRepository()
        return PackageTripsView(viewModel: PackageTripsViewModel(repository: repository))
            .environment(\.layoutDirection, configuration.language.layoutDirection)
    }

    /// Returns the My Trips card for one package booking, in the configured language.
    /// - Parameters:
    ///   - trip: A trip from `fetchPackageTrips(timeframe:offset:limit:years:)`.
    ///   - isPast: `true` in the past-trips list; the badge then reads "Past".
    ///   - onTap: Called when the card is tapped, e.g. to open `getPackageTripConfirmationView(orderId:onBack:)`.
    public func getPackageTripCardView(trip: PackageTrip, isPast: Bool, onTap: @escaping () -> Void) -> some View {
        PackageTripCardView(trip: trip, isPast: isPast, onTap: onTap)
            .environment(\.layoutDirection, configuration.language.layoutDirection)
    }

    /// Returns the booking confirmation for a trip opened from My Trips, with the shared SDK toolbar
    /// (title and back button). "Go to My Trips" goes back; "Back to Home" calls `onBackToHome`.
    /// - Parameter onBack: Called on back / "Go to My Trips". When `nil`, the screen dismisses itself,
    ///   which pops it from a SwiftUI `NavigationStack`. Pass it when the host pushes the view with UIKit.
    public func getPackageTripConfirmationView(orderId: String, onBack: (() -> Void)? = nil) -> some View {
        PackageTripConfirmationView(orderId: orderId, onBack: onBack)
            .environment(\.layoutDirection, configuration.language.layoutDirection)
    }

    // MARK: - Landing Pages

    /// Fetches the landing pages (`GET api/v1/user-recommendation/landing-pages`).
    /// A page that can't be decoded is skipped. Use `LandingPage.imageURL` for the card image
    /// and `isHero` / `heroImageURL` for the hero banner.
    /// Throws when the SDK is not configured, the request fails, or the response cannot be decoded.
    public func fetchLandingPages() async throws -> [LandingPage] {
        try await makeStaticPackagesRepository().fetchLandingPages()
    }

    /// Fetches one landing page with its sections (`GET api/v1/user-recommendation/landing-pages/{id}`).
    /// Pass any of `page.packagesSections` to `getPackagesListView(section:)` to show its packages.
    /// Throws when the SDK is not configured, the request fails, or the response cannot be decoded.
    public func fetchLandingPage(id: String) async throws -> LandingPage {
        try await makeStaticPackagesRepository().fetchLandingPage(id: id)
    }

    // MARK: - Repositories

    func makeStaticPackagesRepository() -> StaticPackagesRepositoryProtocol {
        StaticPackagesRepository(
            baseURL: configuration.baseURL,
            networkClient: dataSource == .mock ? .mock : .shared
        )
    }

    // MARK: - Payment

    /// Hands the payment to the host app and waits for its result.
    func startPayment(_ request: PackagePaymentRequest) async -> PaymentResult {
        guard let delegate else {
            assertionFailure("Set AlmatarStaticPackageSDK.shared.delegate to handle payments.")
            return .failure(.validation(message: LocalizedKey.genericError.localized()))
        }
        return await withCheckedContinuation { continuation in
            delegate.startPayment(
                bookingId: request.bookingId,
                paymentId: request.paymentId,
                amountInSar: request.amountInSar,
                productType: request.productType,
                cancellationTiers: request.cancellationTiers
            ) { result in
                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - Flow

    /// Asks the host app to dismiss the package flow.
    func dismissFlow() {
        onDismiss?()
    }

    /// Keeps the default request headers in line with the current configuration.
    private func syncNetworkClient() {
        NetworkClient.shared.configure(
            brand: configuration.brand,
            deviceId: configuration.deviceId,
            language: configuration.language.rawValue
        )
    }
}
