//
//  PackageTripCardModel.swift
//  AlmatarStaticPackageSDK
//
//  Display model for a My Trips package card: the booking header (title,
//  date range • travellers, status) and one section per included product.
//

import Foundation

struct PackageTripCardModel: Identifiable {
    enum Badge: Equatable {
        case status(PackageTripStatus)
        case past
    }

    let id: String
    let title: String
    /// e.g. "16–24 Jul • 2 travellers".
    let subtitle: String
    let badge: Badge
    let badgeTitle: String
    let products: [Product]

    enum Product: Identifiable {
        case flight(Flight)
        case hotel(Hotel)
        case activity(Activity)

        var id: String {
            switch self {
            case .flight(let model): return "flight-\(model.id)"
            case .hotel(let model): return "hotel-\(model.id)"
            case .activity(let model): return "activity-\(model.id)"
            }
        }
    }

    struct Flight {
        let id: String
        /// e.g. "Jeddah to Riyadh".
        let routeTitle: String
        /// Flight numbers, e.g. "SV-1430 • SV-1431".
        let subtitle: String
        let legs: [FlightLeg]
    }

    struct FlightLeg: Identifiable {
        let id: String
        let logoURL: URL?
        let departureTime: String
        let departureCity: String
        let arrivalTime: String
        let arrivalCity: String
        /// "Direct", "1 stop" or "n stops".
        let stopsTitle: String
        let hasStops: Bool
        /// Free text from the API, e.g. "1h 45m".
        let duration: String
    }

    struct Hotel {
        let id: String
        let title: String
        let imageURL: URL?
        let checkIn: Date?
        let checkOut: Date?
        let checkInTitle: String
        let checkOutTitle: String
        let roomsCount: Int
        let roomsTitle: String
        let nightsCount: Int
        let nightsTitle: String
    }

    struct Activity {
        let id: String
        let title: String
        let subtitle: String
        let imageURL: URL?
    }
}

// MARK: - Mapping

extension PackageTripCardModel {
    @MainActor
    init(trip: PackageTrip, isPast: Bool) {
        id = trip.orderId
        title = trip.title.nonEmpty ?? trip.destination.nonEmpty ?? ""
        subtitle = [Self.dateRange(start: trip.startDate, end: trip.endDate), Self.travellersText(trip.travellersCount)]
            .compactMap { $0 }
            .joined(separator: " • ")
        badge = isPast ? .past : .status(trip.tripStatus)
        badgeTitle = Self.badgeTitle(badge)
        products = trip.products.enumerated().compactMap { index, product in
            switch product.productType {
            case .flight: return Self.flight(product, index: index)
            case .hotel: return Self.hotel(product, index: index)
            case .addon, .unknown: return Self.activity(product, index: index)
            }
        }
    }

    @MainActor
    private static func badgeTitle(_ badge: Badge) -> String {
        switch badge {
        case .past: return LocalizedKey.tripStatusPast.localized()
        case .status(.confirmed): return LocalizedKey.tripStatusConfirmed.localized()
        case .status(.partiallyConfirmed): return LocalizedKey.tripStatusPartiallyConfirmed.localized()
        case .status(.pending): return LocalizedKey.tripStatusPending.localized()
        case .status(.failed): return LocalizedKey.tripStatusFailed.localized()
        case .status(.cancelled): return LocalizedKey.tripStatusCancelled.localized()
        }
    }

    @MainActor
    private static func flight(_ product: PackageTripProduct, index: Int) -> Product? {
        guard let legs = product.flightInfo?.legs, let first = legs.first, let last = legs.last else { return nil }
        let productId = product.productId ?? "flight-\(index)"
        let legModels = legs.enumerated().map { legIndex, leg in
            FlightLeg(
                id: "\(productId)-\(legIndex)",
                logoURL: leg.airline?.logoUrl.nonEmpty.flatMap(URL.init(string:)),
                departureTime: flightTime(leg.departure.time),
                departureCity: leg.departure.cityName.nonEmpty ?? leg.departure.airportCode,
                arrivalTime: flightTime(leg.arrival.time),
                arrivalCity: leg.arrival.cityName.nonEmpty ?? leg.arrival.airportCode,
                stopsTitle: stopsTitle(leg.stops ?? 0),
                hasStops: (leg.stops ?? 0) > 0,
                duration: leg.duration ?? ""
            )
        }
        let routeTitle = LocalizedKey.tripFlightRoute.localized(
            first.departure.cityName.nonEmpty ?? first.departure.airportCode,
            last.arrival.cityName.nonEmpty ?? last.arrival.airportCode
        )
        return .flight(Flight(
            id: productId,
            routeTitle: routeTitle,
            subtitle: legs.compactMap { $0.flightNumber.nonEmpty }.joined(separator: " • "),
            legs: legModels
        ))
    }

    @MainActor
    private static func hotel(_ product: PackageTripProduct, index: Int) -> Product? {
        guard let hotel = product.hotelInfo else { return nil }
        let nights = hotel.nights ?? 0
        return .hotel(Hotel(
            id: product.productId ?? "hotel-\(index)",
            title: product.title.nonEmpty ?? hotel.tagline.nonEmpty ?? hotel.city ?? "",
            imageURL: hotel.imageUrl.nonEmpty.flatMap(URL.init(string:)),
            checkIn: hotel.checkIn.flatMap(PackageTripDateParser.date(fromDay:)),
            checkOut: hotel.checkOut.flatMap(PackageTripDateParser.date(fromDay:)),
            checkInTitle: LocalizedKey.checkIn.localized(),
            checkOutTitle: LocalizedKey.checkOut.localized(),
            // A package books one room per hotel.
            roomsCount: 1,
            roomsTitle: LocalizedKey.tripRoom.localized(),
            nightsCount: nights,
            nightsTitle: (nights == 1 ? LocalizedKey.tripNight : LocalizedKey.tripNights).localized()
        ))
    }

    private static func activity(_ product: PackageTripProduct, index: Int) -> Product? {
        let image = product.addonInfo?.image.nonEmpty ?? product.tags?.first?.icon.nonEmpty
        let title = product.title.nonEmpty ?? product.addonInfo?.title ?? ""
        guard !title.isEmpty || image != nil else { return nil }
        return .activity(Activity(
            id: product.productId ?? "activity-\(index)",
            title: title,
            subtitle: product.description.nonEmpty ?? product.addonInfo?.description ?? "",
            // Tag icons can be icon keys rather than URLs; only real URLs are loaded.
            imageURL: image.flatMap(URL.init(string:)).flatMap { $0.scheme == nil ? nil : $0 }
        ))
    }

    // MARK: Formatting

    @MainActor
    private static func stopsTitle(_ stops: Int) -> String {
        switch stops {
        case 0: return LocalizedKey.flightDirect.localized()
        case 1: return LocalizedKey.flightOneStop.localized()
        default: return LocalizedKey.flightStops.localized(with: stops)
        }
    }

    @MainActor
    private static func travellersText(_ count: Int?) -> String? {
        guard let count, count > 0 else { return nil }
        return count == 1 ? LocalizedKey.oneTraveller.localized() : LocalizedKey.travellersCount.localized(with: count)
    }

    /// ISO 8601 timestamp → "HH:mm" (GMT, as sent by the API).
    private static func flightTime(_ iso: String) -> String {
        guard let date = PackageTripDateParser.date(fromISO: iso) else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    /// "16–24 Jul" from the package's "yyyy-MM-dd" start/end dates, in the SDK language.
    @MainActor
    private static func dateRange(start: String?, end: String?) -> String? {
        guard let start = start.flatMap(PackageTripDateParser.date(fromDay:)) else { return nil }
        let dayMonth = tripDateFormatter("d MMM")
        guard let end = end.flatMap(PackageTripDateParser.date(fromDay:)) else { return dayMonth.string(from: start) }
        return "\(tripDateFormatter("d").string(from: start))–\(dayMonth.string(from: end))"
    }
}

/// A GMT date formatter in the language configured in the SDK.
@MainActor
func tripDateFormatter(_ format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: AlmatarStaticPackageSDK.shared.configuration.language.rawValue)
    formatter.timeZone = TimeZone(identifier: "GMT")
    formatter.dateFormat = format
    return formatter
}
