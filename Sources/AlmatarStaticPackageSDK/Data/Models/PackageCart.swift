//
//  PackageCart.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// A package cart returned by `GET v1/partner/packages/carts/{cartId}`.
struct PackageCart: Codable, Sendable, Identifiable {
    let cartId: String
    /// ISO-8601 date the cart expires at.
    let expiresAt: String?
    let name: String
    let tier: String?
    /// Human-readable duration, e.g. "5 days, 4 nights".
    let duration: String?
    let destination: String?
    let description: String?
    let price: CartPrice
    let heroImageUrl: String?
    let journeySnapshot: [CartSnapshotItem]?
    let products: [CartProduct]?
    let itinerary: [CartItineraryDay]?
    let dynamicForm: CartDynamicForm?
    let cancellationPolicy: CartCancellationPolicy?

    var id: String { cartId }
}

struct CartPrice: Codable, Sendable, Hashable {
    let finalAmount: Decimal
    let currency: String
}

// MARK: - Journey Snapshot

struct CartSnapshotItem: Codable, Sendable, Hashable {
    /// Icon key (e.g. "hotel", "transfer"), a remote image URL, or an SF Symbol name.
    let icon: String
    let label: String
}

extension CartSnapshotItem {
    private static let httpScheme = "http"
    private static let fallbackSymbol = "checkmark.circle"
    private static let symbolsByKey: [String: String] = [
        "hotel": "building.2",
        "transfer": "car",
        "flight": "airplane",
        "ticket": "ticket",
        "meal": "fork.knife",
        "visa": "doc.text",
        "guide": "person.fill",
        "activity": "star"
    ]

    /// Value for `RemoteIconView`: the URL as is, or the SF Symbol for a known icon key.
    var iconName: String {
        if icon.lowercased().hasPrefix(Self.httpScheme) { return icon }
        return Self.symbolsByKey[icon.lowercased()] ?? Self.fallbackSymbol
    }
}

// MARK: - Products

struct CartProduct: Codable, Sendable, Hashable {
    let title: String
    let type: CartProductType
    let mandatory: Bool?
    /// Allocation status, e.g. "allocated".
    let status: String?
    let addonInfo: CartAddonInfo?

    var isMandatory: Bool { mandatory ?? false }
}

enum CartProductType: String, Codable, Sendable {
    case addon
    case flight
    case hotel
    case ticket
    case unknown

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = CartProductType(rawValue: rawValue.lowercased()) ?? .unknown
    }
}

struct CartAddonInfo: Codable, Sendable, Hashable {
    let id: Int
    let key: String?
    let title: String
    let subtitle: String?
    let price: Decimal
    let currency: String
    let quantity: Int?
    let imageUrl: String?
}

// MARK: - Itinerary

struct CartItineraryDay: Codable, Sendable, Hashable {
    let day: Int
    let image: String?
    let title: String
    let description: String?
    let activities: [CartItineraryActivity]?
}

struct CartItineraryActivity: Codable, Sendable, Hashable {
    let name: String
    let duration: String?
    /// Matches `CartAddonInfo.id` of the product covering this activity.
    let productId: Int?
}

// MARK: - Dynamic Form

struct CartDynamicForm: Codable, Sendable, Hashable {
    let sections: [CartFormSection]
}

struct CartFormSection: Codable, Sendable, Hashable {
    /// e.g. "passenger", "departureDate", "departureCity".
    let section: String
    let fields: [CartFormField]
}

struct CartFormField: Codable, Sendable, Hashable {
    let field: String
    let label: String
    let required: Bool
    /// e.g. "string", "date".
    let dataType: String
    let options: [CartFormOption]?
    let dateConfigs: CartDateConfigs?
}

struct CartFormOption: Codable, Sendable, Hashable {
    let code: String
    let name: String
}

struct CartDateConfigs: Codable, Sendable, Hashable {
    /// e.g. "range".
    let type: String
    /// "yyyy-MM-dd".
    let from: String?
    /// "yyyy-MM-dd".
    let to: String?
}

// MARK: - Cancellation Policy

struct CartCancellationPolicy: Codable, Sendable, Hashable {
    let isRefundable: Bool
    /// Ordered from the earliest cancellation window to the latest.
    let policies: [CartCancellationRule]?
}

struct CartCancellationRule: Codable, Sendable, Hashable {
    let minRemainingHours: Int
    let refundableAmountPercentage: Double
    let window: String?
    let note: String?
}
