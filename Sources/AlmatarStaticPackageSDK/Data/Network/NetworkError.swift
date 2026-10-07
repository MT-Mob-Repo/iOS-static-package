//
//  NetworkError.swift
//  AlmatarStaticPackageSDK
//

import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, messages: [String])
    case decodingError(Error)
    case noData
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .httpError(let code, let messages):
            if !messages.isEmpty { return messages.joined(separator: "\n") }
            return "HTTP error: \(code)"
        case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
        case .noData: return "No data received"
        case .unknown(let error): return error.localizedDescription
        }
    }

    /// Messages returned by the backend, if any.
    var apiMessages: [String] {
        if case .httpError(_, let messages) = self { return messages }
        return []
    }
}
