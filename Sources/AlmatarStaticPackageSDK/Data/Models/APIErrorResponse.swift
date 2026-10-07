//
//  APIErrorResponse.swift
//  AlmatarStaticPackageSDK
//

import Foundation

struct APIErrorItem: Decodable {
    let message: String?
}

/// Error body returned by the backend for non-2xx responses.
struct APIErrorResponse: Decodable {
    let status: Int?
    let message: String?
    let error: String?
    // errors can be [String] or [{"message": "..."}]
    let errorObjects: [APIErrorItem]?
    let errorStrings: [String]?

    enum CodingKeys: String, CodingKey {
        case status, message, error, errors
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = try container.decodeIfPresent(Int.self, forKey: .status)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        error = try container.decodeIfPresent(String.self, forKey: .error)

        // Try decoding errors as [APIErrorItem] first, then fall back to [String]
        if let objects = try? container.decodeIfPresent([APIErrorItem].self, forKey: .errors) {
            errorObjects = objects
            errorStrings = nil
        } else if let strings = try? container.decodeIfPresent([String].self, forKey: .errors) {
            errorStrings = strings
            errorObjects = nil
        } else {
            errorObjects = nil
            errorStrings = nil
        }
    }

    /// All non-empty messages, falling back to `message` then `error`.
    var messages: [String] {
        var result: [String] = []
        if let objects = errorObjects {
            result.append(contentsOf: objects.compactMap { $0.message }.filter { !$0.isEmpty })
        }
        if let strings = errorStrings {
            result.append(contentsOf: strings.filter { !$0.isEmpty })
        }
        if result.isEmpty, let message, !message.isEmpty { result.append(message) }
        if result.isEmpty, let error, !error.isEmpty { result.append(error) }
        return result
    }
}
