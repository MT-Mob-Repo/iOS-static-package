//
//  PackageDetails.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Cart returned by `GET v1/packages/carts/{id}`: the selected package,
/// its price and the form the customer fills in to book it.
struct PackageDetails: Codable, Sendable, Identifiable {
    let cartId: String
    /// ISO 8601 date-time after which the cart is no longer valid.
    let expiresAt: String?
    let price: CartPrice?
    let packageInfo: PackageInfo
    let dynamicForm: DynamicForm?

    var id: String { cartId }
}

/// Content of the package shown on the details screen.
struct PackageInfo: Codable, Sendable {
    let packageId: String
    let name: String
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
    let amount: Decimal
    let currency: String
}

struct CartPrice: Codable, Sendable, Hashable {
    let finalAmount: Decimal
    let currency: String
    let breakdown: [PriceBreakdownSection]?
}

/// A group of lines in the price summary (e.g. "Package price"),
/// or a total row (e.g. "Total to pay") when `items` is missing.
struct PriceBreakdownSection: Codable, Sendable, Hashable {
    let title: String
    /// e.g. "Tax included".
    let note: String?
    let amount: Decimal?
    let items: [PriceBreakdownItem]?
}

struct PriceBreakdownItem: Codable, Sendable, Hashable {
    /// e.g. "1x Adult" or "Premium Economy".
    let label: String
    /// e.g. "420 × 2 travelers • Both flights".
    let description: String?
    let unitAmount: Decimal?
    let quantity: Int?
    let amount: Decimal
}
