//
//  Optional+NonEmpty.swift
//  AlmatarStaticPackageSDK
//

import Foundation

extension Optional where Wrapped == String {
    /// The string, or `nil` when it is missing or blank.
    var nonEmpty: String? {
        guard let value = self?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
        return value
    }
}
