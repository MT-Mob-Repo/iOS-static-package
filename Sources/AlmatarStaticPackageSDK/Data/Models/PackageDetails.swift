//
//  PackageDetails.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// A predefined combination of two or more travel components sold as one package.
struct PackageDetails: Codable, Sendable, Identifiable {
    let id: String
    let title: String
    let description: String?
    let imageUrl: String?
    let destination: String?
    let durationNights: Int?
    let price: PackagePrice
    let components: [PackageComponent]

    var mandatoryComponents: [PackageComponent] { components.filter(\.isMandatory) }
    var optionalComponents: [PackageComponent] { components.filter { !$0.isMandatory } }
}

struct PackagePrice: Codable, Sendable, Hashable {
    let amount: Decimal
    let currency: String
}

struct PackageComponent: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let type: PackageComponentType
    let title: String
    let description: String?
    /// Mandatory components are included in the package price and cannot be removed.
    let isMandatory: Bool
    /// Extra cost for optional components; `nil` for mandatory ones.
    let price: PackagePrice?
}

enum PackageComponentType: String, Codable, Sendable {
    case flight
    case hotel
    case car
    case experience
    case addOn = "add_on"
    case unknown

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = PackageComponentType(rawValue: rawValue) ?? .unknown
    }
}
