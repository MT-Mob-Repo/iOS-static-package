//
//  LocalizedKey.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Keys in `Localizable.xcstrings` (en / ar).
enum LocalizedKey: String {
    // MARK: Static Package Details
    case goToPayment = "static_package_details.go_to_payment"
    case journeySnapshot = "static_package_details.journey_snapshot"
    case parkHighlights = "static_package_details.park_highlights"
    case dynamicPackageTag = "static_package_details.dynamic_package_tag"
    case nightsTag = "static_package_details.nights_tag"
    case nightsMeta = "static_package_details.nights_meta"
    case packageSchedule = "static_package_details.package_schedule"
    case includedServices = "static_package_details.included_services"
    case includedServicesSubtitle = "static_package_details.included_services_subtitle"
    case includedInYourPass = "static_package_details.included_in_your_pass"
    case itinerary = "static_package_details.itinerary"
    case itinerarySubtitle = "static_package_details.itinerary_subtitle"
    case itineraryDay = "static_package_details.itinerary_day"
    case itineraryActivities = "static_package_details.itinerary_activities"
    case itineraryIncluded = "static_package_details.itinerary_included"
    case itineraryOptional = "static_package_details.itinerary_optional"
    case itineraryAdd = "static_package_details.itinerary_add"
    case itineraryAdded = "static_package_details.itinerary_added"
    case cancellationPolicy = "static_package_details.cancellation_policy"
    case itineraryDownload = "static_package_details.itinerary_download"
    case hotelRoom = "static_package_details.hotel_room"
    case hotelSleeps = "static_package_details.hotel_sleeps"
    case until = "static_package_details.until"
    case flightUpgraded = "static_package_details.flight_upgraded"
    case flightDirect = "static_package_details.flight_direct"
    case flightOneStop = "static_package_details.flight_one_stop"
    case flightStops = "static_package_details.flight_stops"
    case flightChangeUpgrade = "static_package_details.flight_change_upgrade"

    // MARK: Common
    case genericError = "common.generic_error"
    case retry = "common.retry"
    case readMore = "common.read_more"
    case readLess = "common.read_less"

    /// Localized value in the language currently configured in the SDK, independent of the device language.
    @MainActor
    func localized() -> String {
        let language = AlmatarStaticPackageSDK.shared.configuration.language
        return NSLocalizedString(rawValue, bundle: language.bundle, comment: "")
    }

    /// Localized format string filled with the given arguments.
    @MainActor
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized(), locale: nil, arguments: arguments)
    }
}

private extension AppLanguage {
    /// The `.lproj` bundle for this language inside the SDK, falling back to the SDK bundle.
    var bundle: Bundle {
        guard let path = Bundle.module.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .module
        }
        return bundle
    }
}
