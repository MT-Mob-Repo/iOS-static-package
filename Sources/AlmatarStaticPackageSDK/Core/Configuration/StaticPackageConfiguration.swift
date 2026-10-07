//
//  StaticPackageConfiguration.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Values provided by the host app to configure the SDK.
public struct StaticPackageConfiguration: Sendable {
    /// Backend base URL, e.g. "https://api.almatar.com".
    public var baseURL: String
    /// UI language; also sent as the `Accept-Language` header.
    public var language: AppLanguage
    /// Sent as the `x-brand` header when provided.
    public var brand: String?
    /// Sent as the `device-id` header when provided.
    public var deviceId: String?
    /// Serve bundled mock data through `NetworkClient` instead of calling the backend (until the API is ready).
    public var useMockData: Bool

    public init(
        baseURL: String,
        language: AppLanguage = .english,
        brand: String? = nil,
        deviceId: String? = nil,
        useMockData: Bool = false
    ) {
        self.baseURL = baseURL
        self.language = language
        self.brand = brand
        self.deviceId = deviceId
        self.useMockData = useMockData
    }
}
