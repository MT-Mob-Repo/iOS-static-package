//
//  CancellationPolicy.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// One refund tier of the package cancellation policy.
struct CancellationPolicy: Codable, Sendable, Hashable {
    /// e.g. "Free cancellation".
    let title: String?
    /// e.g. "30+ days before departure".
    let window: String?
    /// Last day the tier applies, "yyyy-MM-dd".
    let until: String?
    /// e.g. "Full refund, except visa fee".
    let note: String?
    /// 100 is a full refund, 0 is no refund.
    let refundableAmountPercentage: Int
}

extension CancellationPolicy {
    /// Sample tiers for previews.
    static let mockItems: [CancellationPolicy] = [
        CancellationPolicy(title: "Free cancellation", window: "30+ days before departure", until: "2026-04-17", note: "Full refund, except visa fee", refundableAmountPercentage: 100),
        CancellationPolicy(title: nil, window: "Less than 30 days", until: nil, note: "Half the amount is refunded.", refundableAmountPercentage: 50)
    ]
}
