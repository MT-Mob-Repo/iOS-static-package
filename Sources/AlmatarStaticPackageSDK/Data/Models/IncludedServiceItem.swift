//
//  IncludedServiceItem.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// A service included in the package price (e.g. All-Day Ride Access).
struct IncludedServiceItem: Codable, Sendable, Identifiable, Hashable {
    let id: String
    /// Remote image URL, or an SF Symbol name.
    let icon: String
    let title: String
    let description: String?
}

extension IncludedServiceItem {
    /// Sample items for previews.
    static let mockItems: [IncludedServiceItem] = [
        IncludedServiceItem(
            id: "rides",
            icon: "car",
            title: "All-Day Ride Access",
            description: "Unlimited access to all roller coasters and attractions."
        ),
        IncludedServiceItem(
            id: "seating",
            icon: "calendar",
            title: "Reserved Show Seating",
            description: "Priority seating for all live shows and entertainment."
        ),
        IncludedServiceItem(
            id: "guide",
            icon: "map",
            title: "Park Map & Guide",
            description: "Digital and physical guide to help you plan your day."
        )
    ]
}
