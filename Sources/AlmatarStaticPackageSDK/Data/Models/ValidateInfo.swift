//
//  ValidateInfo.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Body of `POST v1/packages/validate-info`: the visitors form for the cart, keyed by section.
/// The response `data` is `true` when the details are valid.
struct ValidateInfoRequest: Encodable, Sendable, Equatable {
    let cartId: String
    let sections: [String: Section]

    /// Values of one form section, keyed by field.
    enum Section: Encodable, Sendable, Equatable {
        /// A section filled once, e.g. `"departureCity": { "departureCity": "RUH" }`.
        case single([String: String])
        /// A section filled once per visitor, e.g. `"passenger": [{ "firstName": "Sara", ... }]`.
        case multiple([[String: String]])

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .single(let values):
                try container.encode(values)
            case .multiple(let entries):
                try container.encode(entries)
            }
        }
    }
}
