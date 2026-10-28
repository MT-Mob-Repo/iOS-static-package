//
//  PackageProduct.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// The "Your Park Day" section: the products that make up the package.
struct PackageProducts: Codable, Sendable, Hashable {
    let title: String?
    let subtitle: String?
    let items: [PackageProduct]?
}

/// One product in the package (flight, hotel or add-on).
/// Only the info object matching `productType` is expected to be present.
struct PackageProduct: Codable, Sendable, Hashable {
    /// Sent as `option.productId` when allocating the cart.
    let productId: FlexibleID?
    let title: String
    let description: String?
    let productType: PackageProductType
    /// e.g. "static".
    let inventoryType: String?
    let tags: [PackageProductTag]?
    /// e.g. "allocated".
    let status: String?
    /// Mandatory products are included in the package price and cannot be removed.
    let isMandatory: Bool
    let flightInfo: FlightInfo?
    let hotelInfo: HotelInfo?
    let addonInfo: AddonInfo?
    /// Optional extras the customer can pick for this product (e.g. extra baggage, seat selection).
    let optionsSection: ProductOptionsSection?
}

enum PackageProductType: String, Codable, Sendable {
    case flight
    case hotel
    case addon
    case unknown

    init(from decoder: Decoder) throws {
        let rawValue = try decoder.singleValueContainer().decode(String.self)
        self = PackageProductType(rawValue: rawValue) ?? .unknown
    }
}

struct PackageProductTag: Codable, Sendable, Hashable {
    /// Icon key, remote image URL or SF Symbol name.
    let icon: String?
    let label: String
}

// MARK: - Options

/// The "Options" section of a product: selectable extras with their own price.
struct ProductOptionsSection: Codable, Sendable, Hashable {
    /// Button title, e.g. "Select Options".
    let ctaText: String?
    let title: String?
    let note: String?
    let options: [ProductOption]?
}

struct ProductOption: Codable, Sendable, Hashable {
    /// Sent as `option.optionId` when allocating the cart; the cart API sends it as `id`.
    let optionId: FlexibleID?
    let title: String
    let subTitle: String?
    let price: Double?
    let currency: String?
    let isAvailable: Bool?
    /// `true` when this option is allocated in the cart; `false` when missing.
    let selected: Bool
    /// `true` for the option the product comes with when none is selected; `false` when missing.
    let isDefault: Bool

    private enum CodingKeys: String, CodingKey {
        case optionId, id, title, subTitle, price, currency, isAvailable, selected, isDefault
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        optionId = try container.decodeIfPresent(FlexibleID.self, forKey: .optionId)
            ?? container.decodeIfPresent(FlexibleID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        subTitle = try container.decodeIfPresent(String.self, forKey: .subTitle)
        price = try container.decodeIfPresent(Double.self, forKey: .price)
        currency = try container.decodeIfPresent(String.self, forKey: .currency)
        isAvailable = try container.decodeIfPresent(Bool.self, forKey: .isAvailable)
        selected = try container.decodeIfPresent(Bool.self, forKey: .selected) ?? false
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(optionId, forKey: .optionId)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(subTitle, forKey: .subTitle)
        try container.encodeIfPresent(price, forKey: .price)
        try container.encodeIfPresent(currency, forKey: .currency)
        try container.encodeIfPresent(isAvailable, forKey: .isAvailable)
        try container.encode(selected, forKey: .selected)
        try container.encode(isDefault, forKey: .isDefault)
    }
}

// MARK: - Flight

struct FlightInfo: Codable, Sendable, Hashable {
    let isCabinUpgradeAvailable: Bool?
    let legs: [FlightLeg]
}

struct FlightLeg: Codable, Sendable, Hashable {
    let departure: FlightPoint
    let arrival: FlightPoint
    let airline: Airline?
    let flightNumber: String?
    let cabin: String?
    /// Free text from the API, e.g. "1h 45m".
    let duration: String?
    let stops: Int?
}

struct FlightPoint: Codable, Sendable, Hashable {
    /// ISO 8601 date-time.
    let time: String
    let airportCode: String
    let airportName: String?
    let cityName: String?
    let countryName: String?
}

struct Airline: Codable, Sendable, Hashable {
    let code: String
    let name: String
    let logoUrl: String?
}

// MARK: - Hotel

struct HotelInfo: Codable, Sendable, Hashable {
    let imageUrl: String?
    let starRating: Double?
    let tagline: String?
    let city: String?
    /// "yyyy-MM-dd".
    let checkIn: String?
    /// "yyyy-MM-dd".
    let checkOut: String?
    let nights: Int?
    let room: HotelRoom?
}

struct HotelRoom: Codable, Sendable, Hashable {
    let name: String
    /// e.g. "1 king bed".
    let beds: String?
    let sleeps: Int?
}

// MARK: - Add-on

struct AddonInfo: Codable, Sendable, Hashable {
    let id: Int?
    let key: String?
    let title: String?
    let description: String?
    let image: String?
}
