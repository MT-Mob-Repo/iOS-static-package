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
    public var onGoToMyTrips: (() -> Void)?

    /// Called when the user taps "Back to Home" on the booking confirmation screen.
    public var onBackToHome: (() -> Void)?

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
            onPaymentFinished: { [weak self] in
                self?.dismissFlow()
            }
        )
        return StaticPackageDetailsView(viewModel: viewModel)
            .environment(\.layoutDirection, configuration.language.layoutDirection)
    }
    /// Returns the Package Booking Confirmation screen for the given cart, in the configured language.
    public func getPackageBookingConfirmationView(id: String) -> some View {
        let viewModel = PackageBookingConfimrationViewModel(
            id: id,
            repository: makeStaticPackagesRepository(),
            onGoToMyTrips: { [weak self] in self?.onGoToMyTrips?() },
            onBackToHome: { [weak self] in self?.onBackToHome?() }
        )
        return PackageBookingConfimrationView(viewModel: viewModel)
    }
    
    /// Returns the list of package cards for a section provided by the host app.
    /// "Book" creates a cart for the package, then pushes its details screen,
    /// so the view must be shown inside a `NavigationStack`.
    /// - Parameter section: The title and packages to show, e.g. decoded from the host app's API.
    public func getPackagesListView(section: PackagesSection) -> some View {
        PackagesListView(section: section)
            .environment(\.layoutDirection, configuration.language.layoutDirection)
    }

    // MARK: - Repositories

    func makeStaticPackagesRepository() -> StaticPackagesRepositoryProtocol {
        StaticPackagesRepository(
            baseURL: configuration.baseURL,
            networkClient: configuration.useMockData ? .mock : .shared
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
                bookingKey: request.bookingKey,
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
