//
//  StaticPackagesRepository.swift
//  AlmatarStaticPackageSDK
//

import Foundation

protocol StaticPackagesRepositoryProtocol: Sendable {
    func fetchPackageDetails(cartId: String) async throws -> PackageDetails
    func bookPackage(packageId: String) async throws -> PackageBooking
    func allocateCart(cartId: String, request: CartAllocationRequest) async throws -> CartAllocation
}

enum StaticPackagesEndpoint {
    static let bookPackage = "api/v1/packages/book"
    static let packageCartPrefix = "api/v1/packages/carts/"
    /// `GET v1/packages/carts/{id}`
    static func packageCart(id: String) -> String { packageCartPrefix + id }
    static let allocateSuffix = "/allocate"
    /// `POST v1/packages/carts/{id}/allocate`
    static func allocateCart(id: String) -> String { packageCart(id: id) + allocateSuffix }
}

final class StaticPackagesRepository: StaticPackagesRepositoryProtocol, @unchecked Sendable {
    private let baseURL: String
    private let networkClient: NetworkClient

    init(baseURL: String, networkClient: NetworkClient = .shared) {
        self.baseURL = baseURL
        self.networkClient = networkClient
    }

    func fetchPackageDetails(cartId: String) async throws -> PackageDetails {
        let response: BaseNetworkResponse<PackageDetails> = try await networkClient.get(
            baseURL: baseURL,
            path: StaticPackagesEndpoint.packageCart(id: cartId)
        )
        guard let data = response.data else {
            throw NetworkError.noData
        }
        return data
    }

    func bookPackage(packageId: String) async throws -> PackageBooking {
        let response: BaseNetworkResponse<PackageBooking> = try await networkClient.post(
            baseURL: baseURL,
            path: StaticPackagesEndpoint.bookPackage,
            body: BookPackageRequest(packageId: packageId)
        )
        guard let data = response.data else {
            throw NetworkError.noData
        }
        return data
    }

    func allocateCart(cartId: String, request: CartAllocationRequest) async throws -> CartAllocation {
        let response: BaseNetworkResponse<CartAllocation> = try await networkClient.post(
            baseURL: baseURL,
            path: StaticPackagesEndpoint.allocateCart(id: cartId),
            body: request
        )
        guard let data = response.data else {
            throw NetworkError.noData
        }
        return data
    }
}
