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
    let title: String
    let subTitle: String?
    let price: Double?
    let currency: String?
    let isAvailable: Bool?
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
    let id: Int
    let key: String?
    let title: String
    let description: String?
    let image: String?
}
