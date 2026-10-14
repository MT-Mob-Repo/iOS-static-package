//
//  ParkHighlightItem.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// The package "Park Highlights" section.
struct ParkHighlights: Codable, Sendable, Hashable {
    let title: String?
    let items: [ParkHighlightItem]?
}

/// One card in "Park Highlights" (e.g. Thrills — Record-breaking coasters).
struct ParkHighlightItem: Codable, Sendable, Identifiable, Hashable {
    /// Icon key, remote image URL or SF Symbol name.
    let icon: String
    /// Short label shown above the value, e.g. "Thrills".
    let label: String
    let value: String

    var id: String { "\(icon)-\(label)" }
}

extension ParkHighlightItem {
    /// Sample items for previews.
    static let mockItems: [ParkHighlightItem] = [
        ParkHighlightItem(icon: "thrills", label: "Thrills", value: "Record-breaking coasters"),
        ParkHighlightItem(icon: "water", label: "Water Fun", value: "Splash Island water park"),
        ParkHighlightItem(icon: "dining", label: "Dining", value: "Themed restaurants"),
        ParkHighlightItem(icon: "shows", label: "Shows", value: "Live entertainment"),
        ParkHighlightItem(icon: "family", label: "Family", value: "Kids' play zones"),
        ParkHighlightItem(icon: "night", label: "Night", value: "Fireworks display")
    ]
}
