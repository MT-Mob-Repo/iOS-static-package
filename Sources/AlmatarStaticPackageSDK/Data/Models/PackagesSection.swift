//
//  PackagesSection.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// A titled list of packages provided by the host app, e.g. "Editor's Thrill Picks".
public struct PackagesSection: Codable, Sendable, Hashable {
    public let type: String?
    public let title: String?
    public let packages: [PackageSummary]

    public init(type: String? = nil, title: String?, packages: [PackageSummary]) {
        self.type = type
        self.title = title
        self.packages = packages
    }
}

/// A package card in `PackagesListView`.
public struct PackageSummary: Codable, Sendable, Hashable, Identifiable {
    public let packageId: String
    public let name: String
    public let categories: [String]
    /// Display text, e.g. "2 Days".
    public let duration: String?
    public let description: String?
    /// The first image is shown on the card.
    public let images: [String]
    public let ribbons: [PackageRibbon]
    public let tags: [String]
    public let startingPrice: Decimal?
    public let currency: String?

    public var id: String { packageId }

    public init(
        packageId: String,
        name: String,
        categories: [String] = [],
        duration: String? = nil,
        description: String? = nil,
        images: [String] = [],
        ribbons: [PackageRibbon] = [],
        tags: [String] = [],
        startingPrice: Decimal? = nil,
        currency: String? = nil
    ) {
        self.packageId = packageId
        self.name = name
        self.categories = categories
        self.duration = duration
        self.description = description
        self.images = images
        self.ribbons = ribbons
        self.tags = tags
        self.startingPrice = startingPrice
        self.currency = currency
    }

    enum CodingKeys: String, CodingKey {
        case packageId, name, categories, duration, description, images, ribbons, tags, startingPrice, currency
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        packageId = try container.decode(String.self, forKey: .packageId)
        name = try container.decode(String.self, forKey: .name)
        categories = try container.decodeIfPresent([String].self, forKey: .categories) ?? []
        duration = try container.decodeIfPresent(String.self, forKey: .duration)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        // `images` may arrive as a single URL string or as an array of URLs.
        if let list = try? container.decodeIfPresent([String].self, forKey: .images) {
            images = list
        } else if let single = try? container.decodeIfPresent(String.self, forKey: .images) {
            images = [single]
        } else {
            images = []
        }
        ribbons = try container.decodeIfPresent([PackageRibbon].self, forKey: .ribbons) ?? []
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        startingPrice = try container.decodeIfPresent(Decimal.self, forKey: .startingPrice)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
    }
}

/// Badge on the card image, e.g. "Top sells".
public struct PackageRibbon: Codable, Sendable, Hashable {
    public let text: String
    /// Hex color, e.g. "#E5252A".
    public let color: String?
    /// Remote image URL, or an SF Symbol name.
    public let icon: String?

    public init(text: String, color: String? = nil, icon: String? = nil) {
        self.text = text
        self.color = color
        self.icon = icon
    }
}

public extension PackagesSection {
    /// Sample section for previews and testing the integration.
    static let mock = PackagesSection(
        type: "packages",
        title: "Editor's Thrill Picks",
        packages: [
            PackageSummary(
                packageId: "6ab3f963bb7b185457c9eed7",
                name: "Falcon's Flight Adventure",
                categories: [],
                duration: "2 Days",
                description: "Experience the world's tallest, fastest, and longest roller coaster in one unforgettable day.",
                images: ["https://cdn.alpha.alm6ar.com/landing-pages/pexels-andrea-piacquadio-3771079-1024x673-1789641056418.jpg"],
                ribbons: [PackageRibbon(text: "Top sells", color: "#E5252A", icon: "trophy")],
                tags: ["Fast Pass", "Park Hopper", "VIP Access"],
                startingPrice: 1250,
                currency: "SAR"
            ),
            PackageSummary(
                packageId: "6ab3f963bb7b185457c9eed8",
                name: "Splash Island Getaway",
                categories: ["Family fun", "Water park"],
                duration: "4 Days",
                description: "Lazy rivers, splash pads, and family-friendly slides for every age.",
                images: ["https://cdn.alpha.alm6ar.com/landing-pages/pexels-andrea-piacquadio-3771079-1024x673-1789641056418.jpg"],
                tags: ["Water Park", "Family Zone"],
                startingPrice: 850,
                currency: "SAR"
            )
        ]
    )
}
