//
//  PackageTrip.swift
//  AlmatarStaticPackageSDK
//
//  My Trips list item for Static Packages (`GET v1/packages/orders`).
//

import Foundation

/// Which bookings to load in My Trips.
public enum PackageTripTimeframe: String, CaseIterable, Sendable {
    case upcoming
    case previous
}

/// One page of `GET v1/packages/orders`.
public struct PackageTripsPage: Decodable, Sendable {
    public let trips: [PackageTrip]
    /// Total number of trips for the timeframe, across all pages.
    public let total: Int
    public let page: Int?
    public let limit: Int?
    public let totalPages: Int?

    private enum CodingKeys: String, CodingKey {
        case data, total, page, limit, totalPages
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        trips = try container.decodeIfPresent([PackageTrip].self, forKey: .data) ?? []
        total = try container.decodeIfPresent(Int.self, forKey: .total) ?? trips.count
        page = try container.decodeIfPresent(Int.self, forKey: .page)
        limit = try container.decodeIfPresent(Int.self, forKey: .limit)
        totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages)
    }
}

/// A booked static package, as listed in My Trips.
public struct PackageTrip: Decodable, Sendable, Hashable, Identifiable {
    public let orderId: String
    public let bookingReference: String?
    /// Raw order status, e.g. "confirmed"; see `tripStatus`.
    public let status: String?
    public let bookedAt: String?
    public let travellersCount: Int?
    public let paymentStatus: String?
    let package: PackageTripInfo?
    let price: PackageTripPrice?
    let sections: PackageTripSections?

    public var id: String { orderId }

    /// The package title, e.g. "Six Flags Qiddiya Escape".
    public var title: String? { package?.title }
    public var destination: String? { package?.destination }
    public var imageUrl: String? { package?.imageUrl }
    /// "yyyy-MM-dd".
    public var startDate: String? { package?.startDate }
    /// "yyyy-MM-dd".
    public var endDate: String? { package?.endDate }
    public var priceAmount: Double? { price?.amount }
    public var priceCurrency: String? { price?.currency }

    /// The departure date the trip is grouped by in My Trips.
    public var departureDate: Date? {
        sections?.departureDate?.departureDate.flatMap(PackageTripDateParser.date(fromISO:))
    }

    public var tripStatus: PackageTripStatus { PackageTripStatus(rawStatus: status) }

    var products: [PackageTripProduct] { package?.products ?? [] }

    private enum CodingKeys: String, CodingKey {
        case orderId, bookingReference, status, bookedAt, package, travellersCount, price, paymentStatus, sections
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orderId = try container.decodeIfPresent(FlexibleID.self, forKey: .orderId)?.value ?? ""
        bookingReference = try container.decodeIfPresent(FlexibleID.self, forKey: .bookingReference)?.value
        status = try container.decodeIfPresent(String.self, forKey: .status)
        bookedAt = try container.decodeIfPresent(String.self, forKey: .bookedAt)
        travellersCount = try container.decodeIfPresent(Int.self, forKey: .travellersCount)
        paymentStatus = try container.decodeIfPresent(String.self, forKey: .paymentStatus)
        // Optional parts never fail the whole trip.
        package = try? container.decodeIfPresent(PackageTripInfo.self, forKey: .package)
        price = try? container.decodeIfPresent(PackageTripPrice.self, forKey: .price)
        sections = try? container.decodeIfPresent(PackageTripSections.self, forKey: .sections)
    }
}

/// The booking status shown on the trip card's badge.
public enum PackageTripStatus: Sendable, Hashable {
    case confirmed
    case partiallyConfirmed
    case pending
    case failed
    case cancelled

    init(rawStatus: String?) {
        switch rawStatus?.lowercased() {
        case "confirmed", "payment_confirmed": self = .confirmed
        case "partially confirmed", "partially_confirmed": self = .partiallyConfirmed
        case "failed": self = .failed
        case "cancelled", "canceled": self = .cancelled
        default: self = .pending
        }
    }
}

// MARK: - Supporting Models

struct PackageTripInfo: Decodable, Sendable, Hashable {
    let packageId: String?
    let title: String?
    let destination: String?
    let imageUrl: String?
    let startDate: String?
    let endDate: String?
    let products: [PackageTripProduct]?

    private enum CodingKeys: String, CodingKey {
        case packageId, title, destination, imageUrl, startDate, endDate, products
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        packageId = try container.decodeIfPresent(FlexibleID.self, forKey: .packageId)?.value
        title = try container.decodeIfPresent(String.self, forKey: .title)
        destination = try container.decodeIfPresent(String.self, forKey: .destination)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        // A product that cannot be decoded is skipped instead of dropping the trip.
        products = try container.decodeIfPresent([Lossy<PackageTripProduct>].self, forKey: .products)?
            .compactMap(\.value)
    }
}

/// A product inside a booked package. Lenient on purpose: the orders list may omit
/// fields the cart API always sends (e.g. `isMandatory`).
struct PackageTripProduct: Decodable, Sendable, Hashable {
    let productId: String?
    let title: String?
    let description: String?
    let productType: PackageProductType
    let tags: [PackageProductTag]?
    let flightInfo: FlightInfo?
    let hotelInfo: HotelInfo?
    let addonInfo: AddonInfo?

    private enum CodingKeys: String, CodingKey {
        case productId, title, description, productType, tags, flightInfo, hotelInfo, addonInfo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        productId = try? container.decodeIfPresent(FlexibleID.self, forKey: .productId)?.value
        title = try? container.decodeIfPresent(String.self, forKey: .title)
        description = try? container.decodeIfPresent(String.self, forKey: .description)
        productType = (try? container.decodeIfPresent(PackageProductType.self, forKey: .productType)) ?? .unknown
        tags = try? container.decodeIfPresent([PackageProductTag].self, forKey: .tags)
        flightInfo = try? container.decodeIfPresent(FlightInfo.self, forKey: .flightInfo)
        hotelInfo = try? container.decodeIfPresent(HotelInfo.self, forKey: .hotelInfo)
        addonInfo = try? container.decodeIfPresent(AddonInfo.self, forKey: .addonInfo)
    }
}

struct PackageTripPrice: Decodable, Sendable, Hashable {
    let amount: Double?
    let currency: String?
}

struct PackageTripSections: Decodable, Sendable, Hashable {
    let departureDate: PackageTripDepartureDate?
}

struct PackageTripDepartureDate: Decodable, Sendable, Hashable {
    /// ISO 8601, e.g. "2026-07-16T00:00:00.000Z".
    let departureDate: String?
}

/// Decodes an element, or `nil` when it is malformed.
private struct Lossy<T: Decodable & Sendable>: Decodable, Sendable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

enum PackageTripDateParser {
    /// Parses ISO 8601 with or without fractional seconds.
    static func date(fromISO string: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: string) { return date }
        return ISO8601DateFormatter().date(from: string)
    }

    /// Parses "yyyy-MM-dd" in GMT.
    static func date(fromDay string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)
    }
}
