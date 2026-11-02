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

    /// `until` for display in the SDK language, e.g. "Fri, 17 Apr"; `nil` when missing or not a valid date.
    @MainActor
    var formattedUntil: String? {
        guard let until = until.nonEmpty else { return nil }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.timeZone = TimeZone(identifier: "UTC")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: until) else { return nil }

        let language = AlmatarStaticPackageSDK.shared.configuration.language
        let formatter = DateFormatter()
        // Latin digits in Arabic too, as in the other package dates.
        formatter.locale = Locale(identifier: language.rawValue + "@numbers=latn")
        formatter.timeZone = parser.timeZone
        // Localized so each language uses its own comma.
        formatter.dateFormat = "EEE, d MMM"
        return formatter.string(from: date)
    }
}

extension CancellationPolicy {
    /// Sample tiers for previews.
    static let mockItems: [CancellationPolicy] = [
        CancellationPolicy(title: "Free cancellation", window: "30+ days before departure", until: "2026-04-17", note: "Full refund, except visa fee", refundableAmountPercentage: 100),
        CancellationPolicy(title: nil, window: "Less than 30 days", until: nil, note: "Half the amount is refunded.", refundableAmountPercentage: 50)
    ]
}
