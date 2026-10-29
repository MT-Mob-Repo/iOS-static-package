//
//  PackageDetails.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Cart returned by `GET v1/packages/carts/{id}` and `POST v1/packages/carts/{id}/allocate`:
/// the selected package, its price and the form the customer fills in to book it.
struct PackageDetails: Codable, Sendable, Identifiable {
    let cartId: String
    /// ISO 8601 date-time after which the cart is no longer valid.
    let expiresAt: String?
    let price: CartPrice?
    let packageInfo: PackageInfo
    let dynamicForm: DynamicForm?
    /// Traveller counts the cart is priced for.
    let travellers: CartTravellers?

    var id: String { cartId }
}

/// Traveller counts allocated in the cart.
struct CartTravellers: Codable, Sendable, Hashable {
    let adults: Int?
    let children: Int?
    let infants: Int?
}

/// Content of the package shown on the details screen.
struct PackageInfo: Codable, Sendable {
    let packageId: String
    let name: String
    /// e.g. "2 visitors"; `nil` when not provided.
    let visitorCountLabel: String?
    /// Free text from the API, e.g. "7 nights".
    let duration: String?
    /// Remote image URLs for the header carousel.
    let images: [String]?
    let journeySnapshot: [JourneySnapshotItem]?
    let highlights: ParkHighlights?
    let products: PackageProducts?
    let itinerary: PackageItinerary?
    let includedServices: IncludedServices?
    /// Refund tiers, ordered from the earliest cancellation window.
    let cancellationPolicies: [CancellationPolicy]?
}

// MARK: - Price

struct PackagePrice: Codable, Sendable, Hashable {
    let amount: Double
    let currency: String
}

struct CartPrice: Codable, Sendable, Hashable {
    let finalAmount: Double
    let currency: String
    let breakdown: [PriceBreakdownSection]?
}

/// A group of lines in the price summary (e.g. "Package price"),
/// or a total row (e.g. "Total to pay") when `items` is missing.
struct PriceBreakdownSection: Codable, Sendable, Hashable {
    let title: String
    /// e.g. "Tax included".
    let note: String?
    let amount: Double?
    let items: [PriceBreakdownItem]?
}

struct PriceBreakdownItem: Codable, Sendable, Hashable {
    /// e.g. "1x Adult" or "Premium Economy".
    let label: String
    /// e.g. "420 × 2 travelers • Both flights".
    let description: String?
    let unitAmount: Double?
    let quantity: Int?
    /// The line total; the allocate API sends it as `totalAmount`.
    let amount: Double

    private enum CodingKeys: String, CodingKey {
        case label, description, unitAmount, quantity, amount, totalAmount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        label = try container.decode(String.self, forKey: .label)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        unitAmount = try container.decodeIfPresent(Double.self, forKey: .unitAmount)
        quantity = try container.decodeIfPresent(Int.self, forKey: .quantity)
        amount = try container.decodeIfPresent(Double.self, forKey: .amount)
            ?? container.decode(Double.self, forKey: .totalAmount)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(label, forKey: .label)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(unitAmount, forKey: .unitAmount)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encode(amount, forKey: .amount)
    }
}
