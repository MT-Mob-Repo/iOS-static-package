//
//  StaticPackageDataSource.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Where the SDK loads its data from. The host app switches it at runtime with
/// `AlmatarStaticPackageSDK.setDataSource(_:)`; the initial value comes from
/// `StaticPackageConfiguration.useMockData`.
public enum StaticPackageDataSource: String, CaseIterable, Sendable {
    /// Calls the backend at `baseURL`.
    case remote
    /// Serves the bundled JSON in `Resources/Mocks` for every endpoint, with no network calls.
    /// The data still goes through `NetworkClient`, so decoding and error handling are the same.
    case mock
}
