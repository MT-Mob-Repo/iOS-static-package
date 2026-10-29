//
//  StaticPackagesRepository.swift
//  AlmatarStaticPackageSDK
//

import Foundation

protocol StaticPackagesRepositoryProtocol: Sendable {
    func fetchPackageDetails(cartId: String) async throws -> PackageDetails
    func bookPackage(packageId: String) async throws -> PackageBooking
    func allocateCart(cartId: String, request: CartAllocationRequest) async throws -> CartAllocation
    /// `true` when the visitors' details are accepted for the cart.
    func validateInfo(request: ValidateInfoRequest) async throws -> Bool
    /// Creates the order for the cart.
    func createOrder(cartId: String) async throws -> PackageOrder
    
    func fetchCart(id: String) async throws -> PackageCart
}

enum StaticPackagesEndpoint {
    static let bookPackage = "api/v1/packages/book"
    /// `POST v1/packages/validate-info`
    static let validateInfo = "api/v1/packages/validate-info"
    /// `POST v1/packages/orders`
    static let orders = "api/v1/packages/orders"
    static let packageCartPrefix = "api/v1/packages/carts/"
    /// `GET v1/packages/carts/{id}`
    static func packageCart(id: String) -> String { packageCartPrefix + id }
    
    static let allocateSuffix = "/allocate"
    /// `POST v1/packages/carts/{id}/allocate`
    static func allocateCart(id: String) -> String { packageCart(id: id) + allocateSuffix }

    static let orderPrefix = "api/v1/packages/orders/"
    static func cart(id: String) -> String { orderPrefix + id }
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

    func validateInfo(request: ValidateInfoRequest) async throws -> Bool {
        let response: BaseNetworkResponse<Bool> = try await networkClient.post(
            baseURL: baseURL,
            path: StaticPackagesEndpoint.validateInfo,
            body: request
        )
        guard let data = response.data else {
            throw NetworkError.noData
        }
        return data
    }

    func createOrder(cartId: String) async throws -> PackageOrder {
        let response: BaseNetworkResponse<PackageOrder> = try await networkClient.post(
            baseURL: baseURL,
            path: StaticPackagesEndpoint.orders,
            body: CreateOrderRequest(cartId: cartId)
        )
        guard let data = response.data else {
            throw NetworkError.noData
        }
        return data
    }
    
    func fetchCart(id: String) async throws -> PackageCart {
        let response: BaseNetworkResponse<PackageCart> = try await networkClient.get(
            baseURL: baseURL,
            path: StaticPackagesEndpoint.cart(id: id)
        )
        guard let data = response.data else {
            throw NetworkError.noData
        }
        return data
    }
}
