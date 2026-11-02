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

    typealias Section = VisitorFormSection
}

/// Values of one visitors form section, keyed by field.
/// Sent in `validate-info` and returned in the cart as the details saved so far.
enum VisitorFormSection: Codable, Sendable, Equatable {
    /// A section filled once, e.g. `"departureCity": { "departureCity": "RUH" }`.
    case single([String: String])
    /// A section filled once per visitor, e.g. `"passenger": [{ "firstName": "Sara", ... }]`.
    case multiple([[String: String]])

    /// Values of a `single` section, or of the first entry of a `multiple` one.
    var values: [String: String] {
        switch self {
        case .single(let values): return values
        case .multiple(let entries): return entries.first ?? [:]
        }
    }

    /// Entries of a `multiple` section, or the `single` section's values as one entry.
    var entries: [[String: String]] {
        switch self {
        case .single(let values): return [values]
        case .multiple(let entries): return entries
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let entries = try? container.decode([[String: LenientString]].self) {
            self = .multiple(entries.map(Self.strings))
        } else {
            self = .single(Self.strings(try container.decode([String: LenientString].self)))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .single(let values):
            try container.encode(values)
        case .multiple(let entries):
            try container.encode(entries)
        }
    }

    /// Drops `null` values.
    private static func strings(_ values: [String: LenientString]) -> [String: String] {
        values.compactMapValues(\.value)
    }
}

/// A field value read as text, also when the API sends a number or a boolean; `nil` for `null`.
private struct LenientString: Decodable {
    let value: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            value = nil
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let int = try? container.decode(Int.self) {
            value = String(int)
        } else if let double = try? container.decode(Double.self) {
            value = String(double)
        } else {
            value = String(try container.decode(Bool.self))
        }
    }
}
