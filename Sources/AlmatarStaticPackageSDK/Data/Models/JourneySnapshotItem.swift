//
//  JourneySnapshotItem.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// One highlight in the package "Journey Snapshot" (e.g. location, duration, group size).
struct JourneySnapshotItem: Codable, Sendable, Identifiable, Hashable {
    /// Icon key, remote image URL or SF Symbol name.
    let icon: String
    let label: String

    var id: String { "\(icon)-\(label)" }
}
