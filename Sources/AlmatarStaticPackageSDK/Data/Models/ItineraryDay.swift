//
//  ItineraryDay.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// The package "Itinerary" section.
struct PackageItinerary: Codable, Sendable, Hashable {
    let title: String?
    let subtitle: String?
    /// PDF version of the itinerary.
    let downloadUrl: String?
    let days: [ItineraryDay]?
}

/// One day in the package "Itinerary".
struct ItineraryDay: Codable, Sendable, Identifiable, Hashable {
    let day: Int
    let image: String?
    let title: String
    let description: String?

    var id: Int { day }
}

/// An activity within an itinerary day, either included in the price or an optional extra.
struct ItineraryActivity: Codable, Sendable, Identifiable, Hashable {
    let name: String
    /// Free text from the API, e.g. "1h 30m" or "all day".
    let duration: String?
    let productId: Int
    /// Optional activities can be added by the customer for an extra `price`.
    let isOptional: Bool
    let price: PackagePrice?

    var id: Int { productId }

    enum CodingKeys: String, CodingKey {
        case name, duration, productId, isOptional, price
    }

    init(name: String, duration: String?, productId: Int, isOptional: Bool = false, price: PackagePrice? = nil) {
        self.name = name
        self.duration = duration
        self.productId = productId
        self.isOptional = isOptional
        self.price = price
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        productId = try container.decode(Int.self, forKey: .productId)
        isOptional = try container.decodeIfPresent(Bool.self, forKey: .isOptional) ?? false
        price = try container.decodeIfPresent(PackagePrice.self, forKey: .price)
    }
}

extension ItineraryDay {
    /// Sample days for previews.
    static let mockItems: [ItineraryDay] = [
        ItineraryDay(
            day: 1,
            image: "https://cdn.almatar.com/pkg/day1.jpg",
            title: "Morning – Arrival & First Rides",
            description: "Start your day at Six Flags Qiddiya City with early access to the park's headline rides. Beat the crowds on Falcon's Flight — the world's fastest coaster — before the queues build. Then head to the water park for an afternoon of slides and lazy rivers.",
        ),
        ItineraryDay(day: 2, image: nil, title: "Morning – Arrival & First Rides", description: "Meet your driver and travel to the hotel.")
    ]
}
