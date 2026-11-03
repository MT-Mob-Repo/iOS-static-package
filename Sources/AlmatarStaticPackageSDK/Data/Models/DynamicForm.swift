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
    let section: DynamicFormSectionType
    let title: String?
    /// `true` when the fields are filled once per visitor, e.g. "passenger".
    let isMultiple: Bool?
    let fields: [DynamicFormField]

    var id: String { section.rawValue }
}

/// Section key from the backend; any key not listed decodes as `.unknown` and keeps its raw value.
enum DynamicFormSectionType: Codable, Sendable, Hashable {
    case departureCity
    case departureDate
    case passenger
    case unknown(String)

    init(rawValue: String) {
        switch rawValue {
        case "departureCity": self = .departureCity
        case "departureDate": self = .departureDate
        case "passenger": self = .passenger
        default: self = .unknown(rawValue)
        }
    }

    var rawValue: String {
        switch self {
        case .departureCity: return "departureCity"
        case .departureDate: return "departureDate"
        case .passenger: return "passenger"
        case .unknown(let value): return value
        }
    }

    /// Display order: departure city, departure date, passenger, then any unknown section.
    var sortOrder: Int {
        switch self {
        case .departureCity: return 0
        case .departureDate: return 1
        case .passenger: return 2
        case .unknown: return 3
        }
    }

    init(from decoder: Decoder) throws {
        self.init(rawValue: try decoder.singleValueContainer().decode(String.self))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
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
    case number
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

    init(code: String, name: String) {
        self.code = code
        self.name = name
    }

    /// Accepts `{ "code": "SA", "name": "Saudi Arabia" }` or a plain value such as `"male"`.
    init(from decoder: Decoder) throws {
        if let value = try? decoder.singleValueContainer().decode(String.self) {
            self.init(code: value, name: value)
            return
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            code: try container.decode(String.self, forKey: .code),
            name: try container.decode(String.self, forKey: .name)
        )
    }
}

struct DynamicFormDateConfigs: Codable, Sendable, Hashable {
    /// "list" for a fixed set of dates, or "range" for any date between `from` and `to`.
    let type: String
    /// First selectable date, "yyyy-MM-dd".
    let from: String?
    /// Last selectable date, "yyyy-MM-dd".
    let to: String?
    let options: [DynamicFormDateOption]?
}

struct DynamicFormDateOption: Codable, Sendable, Hashable, Identifiable {
    /// "yyyy-MM-dd".
    let date: String
    /// "yyyy-MM-dd".
    let returnDate: String?

    var id: String { date }

    init(date: String, returnDate: String?) {
        self.date = date
        self.returnDate = returnDate
    }

    /// The backend may send a full timestamp, e.g. "2026-11-21T00:00:00.000Z"; only the day is kept.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            date: Self.day(from: try container.decode(String.self, forKey: .date)),
            returnDate: try container.decodeIfPresent(String.self, forKey: .returnDate).map(Self.day(from:))
        )
    }

    private static func day(from value: String) -> String {
        let dayLength = "yyyy-MM-dd".count
        guard value.count > dayLength,
              value[value.index(value.startIndex, offsetBy: dayLength)] == "T" else { return value }
        return String(value.prefix(dayLength))
    }
}
