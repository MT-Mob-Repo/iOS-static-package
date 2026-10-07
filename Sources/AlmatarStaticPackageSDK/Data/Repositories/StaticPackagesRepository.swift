//
//  StaticPackagesRepository.swift
//  AlmatarStaticPackageSDK
//

import Foundation

protocol StaticPackagesRepositoryProtocol: Sendable {
    func fetchPackageDetails(packageId: String) async throws -> PackageDetails
}

enum StaticPackagesEndpoint {
    // TODO: Confirm the path with the backend team.
    static let packageDetailsPrefix = "api/v1/static-packages/"

    static func packageDetails(id: String) -> String { packageDetailsPrefix + id }
}

final class StaticPackagesRepository: StaticPackagesRepositoryProtocol, @unchecked Sendable {
    private let baseURL: String
    private let networkClient: NetworkClient

    init(baseURL: String, networkClient: NetworkClient = .shared) {
        self.baseURL = baseURL
        self.networkClient = networkClient
    }

    func fetchPackageDetails(packageId: String) async throws -> PackageDetails {
        let response: BaseNetworkResponse<PackageDetails> = try await networkClient.get(
            baseURL: baseURL,
            path: StaticPackagesEndpoint.packageDetails(id: packageId)
        )
        guard let details = response.data else {
            throw NetworkError.noData
        }
        return details
    }
}
