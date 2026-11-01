//
//  PackageCart.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// A booked package order returned by `GET v1/partner/packages/carts/{cartId}`.
struct PackageCart: Codable, Sendable, Identifiable {
    let orderId: String
    /// Reference shown to the customer, e.g. "300000733".
    let bookingReference: String
    /// e.g. "confirmed".
    let status: String?
    let failureReason: String?
    /// ISO 8601 date-time the order was booked at.
    let bookedAt: String?
    /// Full package content (same shape as the details screen), including product details.
    let packageInfo: PackageInfo
    let travellers: [CartTraveller]?
    /// The products booked in this order, with the option picked for each.
    let products: [CartProduct]?
    let payment: CartPayment
    /// Refund tiers, ordered from the earliest cancellation window.
    let cancellationPolicies: [CancellationPolicy]?

    var id: String { orderId }

    /// Rich product details (flight legs, hotel info...) from `packageInfo.products.items`.
    var packageProducts: [PackageProduct] { packageInfo.products?.items ?? [] }
}

// MARK: - Booked Products

/// One booked product in `PackageCart.products`.
struct CartProduct: Codable, Sendable, Hashable {
    let title: String?
    let type: PackageProductType
    let status: String?
    let option: CartProductOption?
    let addonInfo: CartProductAddonInfo?
}

struct CartProductOption: Codable, Sendable, Hashable {
    let id: FlexibleID?
    let title: String?
    let price: Double?
}

struct CartProductAddonInfo: Codable, Sendable, Hashable {
    let id: FlexibleID?
    let key: String?
    let title: String?
    let price: Double?
    let currency: String?
    let quantity: Int?
}

// MARK: - Travellers

struct CartTraveller: Codable, Sendable, Hashable {
    let firstName: String
    let lastName: String
    let isMainGuest: Bool
    /// `true` once the traveller's documents were verified.
    let isVerified: Bool?

    var fullName: String { "\(firstName) \(lastName)" }
}

// MARK: - Payment

struct CartPayment: Codable, Sendable, Hashable {
    let paymentId: String
    let currency: String
    let totalPaid: Decimal
    let finalAmount: Decimal?
    /// e.g. "success".
    let status: String?
    let breakdown: [PriceBreakdownSection]?
    /// The card used to pay, when the API returns it.
    let paymentMethod: CartPaymentMethod?
}

struct CartPaymentMethod: Codable, Sendable, Hashable {
    /// e.g. "Visa".
    let brand: String?
    /// Last four digits of the card, e.g. "4629".
    let last4: String?
}

// MARK: - Icons

extension JourneySnapshotItem {
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
        "activity": "star",
        "wifi": "wifi"
    ]

    /// Value for `RemoteIconView`: the URL as is, or the SF Symbol for a known icon key.
    var iconName: String {
        if icon.lowercased().hasPrefix(Self.httpScheme) { return icon }
        return Self.symbolsByKey[icon.lowercased()] ?? Self.fallbackSymbol
    }
}
