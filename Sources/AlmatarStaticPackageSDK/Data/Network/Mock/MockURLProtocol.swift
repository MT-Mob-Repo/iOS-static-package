//
//  MockURLProtocol.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Serves bundled JSON files from `Resources/Mocks` instead of hitting the backend,
/// so mock data still flows through `NetworkClient` (request building, status check, decoding).
final class MockURLProtocol: URLProtocol {
    private enum Constants {
        static let fileExtension = "json"
        static let contentType = "application/json"
        static let httpVersion = "HTTP/1.1"
        static let okStatus = 200
        static let notFoundStatus = 404
        /// Simulated network latency.
        static let delay: TimeInterval = 0.5
    }

    /// Maps an endpoint path to a mock file name in `Resources/Mocks`; the first match wins.
    private static let routes: [(matches: (String) -> Bool, fileName: String)] = [
        ({ $0.hasPrefix(StaticPackagesEndpoint.packageCartPrefix) && $0.hasSuffix(StaticPackagesEndpoint.allocateSuffix) }, "cart_allocate"),
        ({ $0.hasPrefix(StaticPackagesEndpoint.packageCartPrefix) }, "package_details"),
        ({ $0.hasPrefix(StaticPackagesEndpoint.bookPackage) }, "book_package"),
        ({ $0.hasPrefix(StaticPackagesEndpoint.validateInfo) }, "validate_info")
    ]

    override class func canInit(with request: URLRequest) -> Bool { true }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        DispatchQueue.global().asyncAfter(deadline: .now() + Constants.delay) { [weak self] in
            self?.respond()
        }
    }

    override func stopLoading() {}

    private func respond() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let data = Self.mockData(for: url)
        let statusCode = data == nil ? Constants.notFoundStatus : Constants.okStatus
        let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: Constants.httpVersion,
            headerFields: ["Content-Type": Constants.contentType]
        )

        if let response {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        client?.urlProtocol(self, didLoad: data ?? Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    private static func mockData(for url: URL) -> Data? {
        let path = url.path.hasPrefix("/") ? String(url.path.dropFirst()) : url.path
        guard let route = routes.first(where: { $0.matches(path) }),
              let fileURL = Bundle.module.url(forResource: route.fileName, withExtension: Constants.fileExtension) else {
            return nil
        }
        return try? Data(contentsOf: fileURL)
    }
}

extension NetworkClient {
    /// A client that returns bundled mock data for every request.
    static let mock: NetworkClient = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return NetworkClient(configuration: configuration)
    }()
}
