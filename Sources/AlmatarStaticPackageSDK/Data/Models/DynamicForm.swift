//
//  DynamicForm.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Booking form described by the backend (departure city, date and travellers).
struct DynamicForm: Codable, Sendable, Hashable {
    let title: String?
    let subtitle: String?
    let sections: [DynamicFormSection]
}

struct DynamicFormSection: Codable, Sendable, Hashable, Identifiable {
    /// Section key, e.g. "departureCity", "departureDate" or "travellers".
    let section: String
    let title: String?
    let fields: [DynamicFormField]

    var id: String { section }
}

struct DynamicFormField: Codable, Sendable, Hashable, Identifiable {
    /// Field key sent back to the backend, e.g. "firstName".
    let field: String
    let label: String
    let required: Bool
    let dataType: DynamicFormDataType
    /// Choices for picker fields; empty for free input.
    let options: [DynamicFormOption]?
    let dateConfigs: DynamicFormDateConfigs?

    var id: String { field }
}

enum DynamicFormDataType: String, Codable, Sendable {
    case string
    case date
    case email
    case phone
    case unknown

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = DynamicFormDataType(rawValue: rawValue) ?? .unknown
    }
}

struct DynamicFormOption: Codable, Sendable, Hashable, Identifiable {
    let code: String
    let name: String

    var id: String { code }
}

struct DynamicFormDateConfigs: Codable, Sendable, Hashable {
    /// e.g. "list" for a fixed set of dates.
    let type: String
    let options: [DynamicFormDateOption]?
}

struct DynamicFormDateOption: Codable, Sendable, Hashable, Identifiable {
    /// "yyyy-MM-dd".
    let date: String
    /// "yyyy-MM-dd".
    let returnDate: String?

    var id: String { date }
}
