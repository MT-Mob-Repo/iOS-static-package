//
//  IncludedServiceItem.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// The package "Included Services" section.
struct IncludedServices: Codable, Sendable, Hashable {
    /// Section title, e.g. "Included Services".
    let title: String?
    /// Text under the title, e.g. "Confirm or customize your configuration below".
    let description: String?
    /// Heading above the list, e.g. "Included in Your Pass".
    let subtitle: String?
    let items: [IncludedServiceItem]?
}

/// A service included in the package price (e.g. All-Day Ride Access).
struct IncludedServiceItem: Codable, Sendable, Identifiable, Hashable {
    /// Icon key, remote image URL or SF Symbol name.
    let icon: String
    let title: String
    let description: String?

    var id: String { "\(icon)-\(title)" }
}

extension IncludedServiceItem {
    /// Sample items for previews.
    static let mockItems: [IncludedServiceItem] = [
        IncludedServiceItem(icon: "rides", title: "All-Day Ride Access", description: "Unlimited access to all roller coasters and attractions."),
        IncludedServiceItem(icon: "seat", title: "Reserved Show Seating", description: "Priority seating for all live shows and entertainment."),
        IncludedServiceItem(icon: "map", title: "Park Map & Guide", description: "Digital and physical guide to help you plan your day.")
    ]
}
