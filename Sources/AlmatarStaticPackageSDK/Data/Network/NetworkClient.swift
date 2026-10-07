//
//  NetworkClient.swift
//  AlmatarStaticPackageSDK
//

import Foundation

// MARK: - Constants

private enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}

private enum HTTPHeader {
    static let accept = "Accept"
    static let contentType = "Content-Type"
    static let acceptLanguage = "Accept-Language"
    static let brand = "x-brand"
    static let platform = "platform"
    static let version = "version"
    static let deviceId = "device-id"
    static let authorization = "Authorization"
}

private enum AuthScheme {
    static let bearer = "Bearer"
}

private enum MimeType {
    static let json = "application/json"
    static let multipart = "multipart/form-data"
}

private enum PlatformValue {
    static let iOS = "ios"
}

// MARK: - Network Client

final class NetworkClient: @unchecked Sendable {

    static let shared = NetworkClient()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // Default metadata passed with every request; guarded by `lock`
    // because configuration happens on the main actor while requests run in the background.
    private let lock = NSLock()
    private var brand: String?
    private var deviceId: String?
    private var language: String?
    private var tokenProvider: TokenProvider?
    private var headersProvider: HeadersProvider?

    init(configuration: URLSessionConfiguration = .default) {
        let config = configuration
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    /// Configure default metadata to be passed with each request.
    func configure(brand: String?, deviceId: String?, language: String?) {
        lock.withLock {
            self.brand = brand
            self.deviceId = deviceId
            self.language = language
        }
    }

    /// Sets the host-app provider for the `Authorization` token.
    func setTokenProvider(_ provider: TokenProvider?) {
        lock.withLock { tokenProvider = provider }
    }

    /// Sets the host-app provider for extra request headers.
    func setHeadersProvider(_ provider: HeadersProvider?) {
        lock.withLock { headersProvider = provider }
    }

    // MARK: - Requests

    /// Performs an async GET request and decodes the response.
    func get<T: Decodable>(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var request = try await makeRequest(baseURL: baseURL, path: path, queryItems: queryItems, method: .get)
        request.setValue(MimeType.json, forHTTPHeaderField: HTTPHeader.accept)
        return try await perform(request)
    }

    /// Performs an async POST request with a JSON body and decodes the response.
    func post<T: Decodable, U: Encodable>(
        baseURL: String,
        path: String,
        body: U
    ) async throws -> T {
        var request = try await makeRequest(baseURL: baseURL, path: path, method: .post)
        request.setValue(MimeType.json, forHTTPHeaderField: HTTPHeader.contentType)
        request.setValue(MimeType.json, forHTTPHeaderField: HTTPHeader.accept)

        do {
            request.httpBody = try encoder.encode(body)
        } catch {
            throw NetworkError.unknown(error)
        }
        return try await perform(request)
    }

    /// Performs an async POST request with multipart/form-data and decodes the response.
    func upload<T: Decodable>(
        baseURL: String,
        path: String,
        fileData: Data,
        fileName: String = "file.jpg",
        mimeType: String = "image/jpeg"
    ) async throws -> T {
        var request = try await makeRequest(baseURL: baseURL, path: path, method: .post)
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("\(MimeType.multipart); boundary=\(boundary)", forHTTPHeaderField: HTTPHeader.contentType)
        request.setValue(MimeType.json, forHTTPHeaderField: HTTPHeader.accept)

        var body = Data()
        body.append(Data("--\(boundary)\r\n".utf8))
        body.append(Data("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\r\n".utf8))
        body.append(Data("Content-Type: \(mimeType)\r\n\r\n".utf8))
        body.append(fileData)
        body.append(Data("\r\n".utf8))
        body.append(Data("--\(boundary)--\r\n".utf8))

        return try await perform(request) { [session] in
            try await session.upload(for: request, from: body)
        }
    }

    // MARK: - Helpers

    private func makeRequest(
        baseURL: String,
        path: String,
        queryItems: [URLQueryItem] = [],
        method: HTTPMethod
    ) async throws -> URLRequest {
        let urlString = baseURL.hasSuffix("/") ? baseURL + path : baseURL + "/" + path

        guard var components = URLComponents(string: urlString) else {
            throw NetworkError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        await applyHeaders(to: &request)
        return request
    }

    /// Applies headers in order: SDK defaults, then host headers (which may override them),
    /// then the host token as `Authorization`.
    private func applyHeaders(to request: inout URLRequest) async {
        let (brand, deviceId, language, tokenProvider, headersProvider) = currentSettings()

        if let brand {
            request.setValue(brand, forHTTPHeaderField: HTTPHeader.brand)
        }
        request.setValue(PlatformValue.iOS, forHTTPHeaderField: HTTPHeader.platform)
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            request.setValue(version, forHTTPHeaderField: HTTPHeader.version)
        }
        if let deviceId {
            request.setValue(deviceId, forHTTPHeaderField: HTTPHeader.deviceId)
        }
        if let language {
            request.setValue(language, forHTTPHeaderField: HTTPHeader.acceptLanguage)
        }

        if let headersProvider {
            for (field, value) in await headersProvider() {
                request.setValue(value, forHTTPHeaderField: field)
            }
        }

        if let token = await tokenProvider?(), !token.isEmpty {
            request.setValue("\(AuthScheme.bearer) \(token)", forHTTPHeaderField: HTTPHeader.authorization)
        }
    }

    /// Thread-safe snapshot of the configured metadata and providers.
    private func currentSettings() -> (
        brand: String?,
        deviceId: String?,
        language: String?,
        tokenProvider: TokenProvider?,
        headersProvider: HeadersProvider?
    ) {
        lock.withLock { (brand, deviceId, language, tokenProvider, headersProvider) }
    }

    /// Sends the request, validates the status code, and decodes the body.
    /// `send` defaults to a plain data task; uploads pass their own.
    private func perform<T: Decodable>(
        _ request: URLRequest,
        send: (() async throws -> (Data, URLResponse))? = nil
    ) async throws -> T {
        do {
            let (data, response): (Data, URLResponse)
            if let send {
                (data, response) = try await send()
            } else {
                (data, response) = try await session.data(for: request)
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let messages = parseErrorMessages(from: data)
                throw NetworkError.httpError(statusCode: httpResponse.statusCode, messages: messages)
            }

            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingError(error)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    private func parseErrorMessages(from data: Data) -> [String] {
        guard let errorResponse = try? decoder.decode(APIErrorResponse.self, from: data) else {
            return []
        }
        return errorResponse.messages
    }
}
