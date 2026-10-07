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

    /// Called when the user taps "Go to payment".
    /// The host app handles the payment using its existing payment flow.
    public var onGoToPayment: (() -> Void)?

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
    public func getStaticPackageDetailsView(packageId: String) -> some View {
        let language = configuration.language
        let viewModel = StaticPackageDetailsViewModel(
            packageId: packageId,
            language: language,
            repository: makeStaticPackagesRepository()
        ) { [weak self] in
            self?.onGoToPayment?()
        }
        return StaticPackageDetailsView(viewModel: viewModel)
            .environment(\.layoutDirection, language.layoutDirection)
    }

    // MARK: - Repositories

    private func makeStaticPackagesRepository() -> StaticPackagesRepositoryProtocol {
        StaticPackagesRepository(
            baseURL: configuration.baseURL,
            networkClient: configuration.useMockData ? .mock : .shared
        )
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
