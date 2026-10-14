//
//  StaticPackagesRepository.swift
//  AlmatarStaticPackageSDK
//

import Foundation

protocol StaticPackagesRepositoryProtocol: Sendable {
    func fetchPackageDetails(cartId: String) async throws -> PackageDetails
}

enum StaticPackagesEndpoint {
    static let packageCartPrefix = "v1/packages/carts/"

    /// `GET v1/packages/carts/{id}`
    static func packageCart(id: String) -> String { packageCartPrefix + id }
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
}
