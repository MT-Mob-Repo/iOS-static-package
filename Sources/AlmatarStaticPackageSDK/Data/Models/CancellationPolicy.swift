//
//  CancellationPolicy.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Refund rules for the package, ordered from the earliest cancellation window.
struct CancellationPolicy: Codable, Sendable, Hashable {
    let isRefundable: Bool
    let policies: [CancellationPolicyRule]?
}

struct CancellationPolicyRule: Codable, Sendable, Hashable {
    /// The rule applies when at least this many hours remain before departure.
    let minRemainingHours: Int
    /// 100 is a full refund, 0 is no refund.
    let refundableAmountPercentage: Int
    /// e.g. "More than 48 hours before departure".
    let window: String?
    /// e.g. "Cancel for a full refund."
    let note: String?
}

extension CancellationPolicy {
    /// Sample policy for previews.
    static let mock = CancellationPolicy(
        isRefundable: true,
        policies: [
            CancellationPolicyRule(
                minRemainingHours: 48,
                refundableAmountPercentage: 100,
                window: "More than 48 hours before departure",
                note: "Cancel for a full refund."
            ),
            CancellationPolicyRule(
                minRemainingHours: 0,
                refundableAmountPercentage: 50,
                window: "Less than 48 hours",
                note: "Half the amount is refunded."
            )
        ]
    )
}
