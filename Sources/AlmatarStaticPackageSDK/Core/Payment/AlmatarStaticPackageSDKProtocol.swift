//
//  AlmatarStaticPackageSDKProtocol.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Implemented by the host app to run its own payment flow for a package booking.
/// Set it on `AlmatarStaticPackageSDK.shared.delegate`.
public protocol AlmatarStaticPackageSDKProtocol: AnyObject {
    /// Opens the host app's payment screen and reports the outcome through `completion`.
    /// `completion` may be called on any thread.
    func startPayment(
        bookingId: String,
        bookingKey: String,
        amountInSar: Float,
        productType: String,
        completion: @escaping (AlmatarStaticPackageSDK.PaymentResult) -> Void
    )
}

public extension AlmatarStaticPackageSDK {
    /// The outcome of `startPayment`.
    /// Spelled out here with `Swift.Result` so host apps that declare their own `Result` type
    /// can implement the protocol without a name clash.
    typealias PaymentResult = Swift.Result<AlmatarPaymentStatus, AlmatarError>

    enum AlmatarPaymentStatus: Sendable {
        case success
        case failed
        case pending
    }

    enum AlmatarError: Error, Sendable {
        case paymentFailed(reason: String)
        case validation(message: String)
    }
}

/// Values the SDK sends to `startPayment`.
struct PackagePaymentRequest: Sendable, Equatable {
    // TODO: Confirm the product type value with the backend / payment team.
    static let productType = "package"

    let bookingId: String
    let bookingKey: String
    let amountInSar: Float
    let productType: String
}
