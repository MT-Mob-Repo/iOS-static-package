//
//  PackageOrder.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Body of `POST v1/packages/orders`.
struct CreateOrderRequest: Encodable, Sendable, Equatable {
    let cartId: String
}

/// Order created for a cart by `POST v1/packages/orders`.
struct PackageOrder: Codable, Sendable, Hashable {
    let orderId: String
    let paymentId: String
}
