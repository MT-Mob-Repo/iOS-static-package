//
//  CartAllocation.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Body of `POST v1/packages/carts/{cartId}/allocate`.
/// Sends one change at a time: either a traveller count or a product option.
struct CartAllocationRequest: Encodable, Sendable, Equatable {
    struct Traveller: Encodable, Sendable, Equatable {
        /// "adult", "child" or "infant".
        let type: String
        /// The new total for this traveller type, e.g. 2 adults.
        let quantity: Int
    }

    struct Option: Encodable, Sendable, Equatable {
        let productId: String
        /// `nil` for a product without options.
        let optionId: String?
    }

    let packageId: String
    let traveller: Traveller?
    let option: Option?

    static func traveller(packageId: String, type: String, quantity: Int) -> Self {
        CartAllocationRequest(packageId: packageId, traveller: Traveller(type: type, quantity: quantity), option: nil)
    }

    static func option(packageId: String, productId: String, optionId: String?) -> Self {
        CartAllocationRequest(packageId: packageId, traveller: nil, option: Option(productId: productId, optionId: optionId))
    }
}

/// Response of `POST v1/packages/carts/{cartId}/allocate`: the cart id, expiry and re-calculated price.
struct CartAllocation: Codable, Sendable, Hashable {
    let cartId: String
    /// ISO 8601 date-time after which the cart is no longer valid.
    let expiresAt: String?
    let price: CartPrice?
}

/// An id the API may send as a string or a number; always encoded back as a string.
struct FlexibleID: Codable, Sendable, Hashable {
    let value: String

    init(_ value: String) { self.value = value }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else {
            value = String(try container.decode(Int.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
