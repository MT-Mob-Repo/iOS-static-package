//
//  StaticPackagesRepository.swift
//  AlmatarStaticPackageSDK
//

import Foundation

protocol StaticPackagesRepositoryProtocol: Sendable {
    func fetchPackageDetails(packageId: String) async throws -> PackageDetails
    func fetchCart(cartId: String) async throws -> PackageCart
    func fetchPackageDetails(cartId: String) async throws -> PackageDetails
    func bookPackage(packageId: String) async throws -> PackageBooking
}

enum StaticPackagesEndpoint {
    // TODO: Confirm the path with the backend team.
    static let packageDetailsPrefix = "api/v1/static-packages/"
    static func packageDetails(id: String) -> String { packageDetailsPrefix + id }
    static let cartPrefix = "v1/partner/packages/carts/"
    static func cart(id: String) -> String { cartPrefix + id }
}

final class StaticPackagesRepository: StaticPackagesRepositoryProtocol, @unchecked Sendable {
    private let baseURL: String
    private let networkClient: NetworkClient

    init(baseURL: String, networkClient: NetworkClient = .shared) {
        self.baseURL = baseURL
        self.networkClient = networkClient
    }

    func fetchPackageDetails(cartId: String) async throws -> PackageDetails {
        // The cart is returned at the root of the body, without a `data` envelope.
        try await networkClient.get(
            baseURL: baseURL,
            path: StaticPackagesEndpoint.packageCart(id: cartId)
        )
    }

    func bookPackage(packageId: String) async throws -> PackageBooking {
        try await networkClient.post(
            baseURL: baseURL,
            path: StaticPackagesEndpoint.bookPackage,
            body: BookPackageRequest(packageId: packageId)
        )
    }

    func fetchCart(cartId: String) async throws -> PackageCart {
        // The carts endpoint returns the cart at the top level, without a `data` wrapper.
        try await networkClient.get(
            baseURL: baseURL,
            path: StaticPackagesEndpoint.cart(id: cartId)
        )
    }
}
