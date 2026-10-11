//
//  ParkHighlightItem.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// One card in the package "Park Highlights" (e.g. Thrills — Record-breaking coasters).
struct ParkHighlightItem: Codable, Sendable, Identifiable, Hashable {
    let id: String
    /// Remote image URL, or an SF Symbol name.
    let icon: String
    /// Short label shown above the title, e.g. "Thrills".
    let category: String
    let title: String
}

extension ParkHighlightItem {
    /// Sample items for previews.
    static let mockItems: [ParkHighlightItem] = [
        ParkHighlightItem(id: "thrills", icon: "bag", category: "Thrills", title: "Record-breaking coasters"),
        ParkHighlightItem(id: "water", icon: "doc.on.doc", category: "Water Fun", title: "Splash Island water park"),
        ParkHighlightItem(id: "dining", icon: "fork.knife", category: "Dining", title: "Themed restaurants"),
        ParkHighlightItem(id: "shows", icon: "percent", category: "Shows", title: "Live entertainment"),
        ParkHighlightItem(id: "family", icon: "car", category: "Family", title: "Kids' play zones"),
        ParkHighlightItem(id: "night", icon: "clock", category: "Night", title: "Fireworks display")
    ]
}
