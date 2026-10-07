//
//  RequestProviders.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Returns the current access token, or `nil` for guest users.
/// Called before every request, so the host app can refresh an expired token here.
public typealias TokenProvider = @Sendable () async -> String?

/// Returns extra headers to attach to every request (e.g. session or tracking headers).
public typealias HeadersProvider = @Sendable () async -> [String: String]
