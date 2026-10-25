//
//  PackageBooking.swift
//  AlmatarStaticPackageSDK
//

import Foundation

struct BookPackageRequest: Encodable, Sendable {
    let packageId: String
}

/// Cart created for a package by `POST v1/packages/book`.
struct PackageBooking: Decodable, Encodable, Sendable, Hashable {
    let cartId: String
    /// ISO 8601 date when the cart expires, e.g. "2026-07-01T14:32:00.000Z".
    let expiresAt: String?
}
