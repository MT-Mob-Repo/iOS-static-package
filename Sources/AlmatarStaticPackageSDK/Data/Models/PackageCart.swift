//
//  PackageCart.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// A booked package order returned by `GET v1/partner/packages/carts/{cartId}`.
struct PackageCart: Codable, Sendable, Identifiable {
    let orderId: String
    /// Reference shown to the customer, e.g. "SFQ-6S03U3".
    let bookingReference: String
    /// e.g. "confirmed".
    let status: String?
    let failureReason: String?
    /// ISO 8601 date-time the order was booked at.
    let bookedAt: String?
    let packageSummary: CartPackageSummary
    let travellers: [CartTraveller]?
    let products: [PackageProduct]?
    let payment: CartPayment
    /// Refund tiers, ordered from the earliest cancellation window.
    let cancellationPolicies: [CancellationPolicy]?

    var id: String { orderId }
}

// MARK: - Package Summary

struct CartPackageSummary: Codable, Sendable, Hashable {
    let packageId: String
    let title: String
    let destination: String?
    /// "yyyy-MM-dd".
    let startDate: String?
    /// "yyyy-MM-dd".
    let endDate: String?
    /// e.g. "VIP access".
    let badges: [String]?
    let includes: [JourneySnapshotItem]?
}

// MARK: - Travellers

struct CartTraveller: Codable, Sendable, Hashable {
    let firstName: String
    let lastName: String
    let isMainGuest: Bool

    var fullName: String { "\(firstName) \(lastName)" }
}

// MARK: - Payment

struct CartPayment: Codable, Sendable, Hashable {
    let paymentId: String
    let currency: String
    let totalPaid: Decimal
    /// e.g. "success".
    let status: String?
    let breakdown: [PriceBreakdownSection]?
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
        "activity": "star"
    ]

    /// Value for `RemoteIconView`: the URL as is, or the SF Symbol for a known icon key.
    var iconName: String {
        if icon.lowercased().hasPrefix(Self.httpScheme) { return icon }
        return Self.symbolsByKey[icon.lowercased()] ?? Self.fallbackSymbol
    }
}
