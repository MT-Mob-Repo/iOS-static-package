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
    case visitorDetails = "static_package_details.visitor_details"
    case adults = "static_package_details.adults"
    case children = "static_package_details.children"
    case infants = "static_package_details.infants"
    case adultsAgeHint = "static_package_details.adults_age_hint"
    case childrenAgeHint = "static_package_details.children_age_hint"
    case infantsAgeHint = "static_package_details.infants_age_hint"

    // MARK: Packages List
    case startingFrom = "packages_list.starting_from"
    case perTicket = "packages_list.per_ticket"
    case book = "packages_list.book"

    // MARK: Common
    case genericError = "common.generic_error"
    case retry = "common.retry"
    case ok = "common.ok"
    case readMore = "common.read_more"
    case readLess = "common.read_less"
    case select = "common.select"
    case close = "common.close"
    case selectVisitDate = "visitor_details.select_visit_date"
    case confirmDates = "visitor_details.confirm_dates"
    case availableCount = "visitor_details.available_count"
    case returnDateAutoSet = "visitor_details.return_date_auto_set"
    case weekdayDayMonthFormat = "visitor_details.weekday_day_month_format"
    case visitorsInformation = "visitor_details.visitors_information"
    case leadVisitor = "visitor_details.lead_visitor"
    case visitorNumber = "visitor_details.visitor_number"
    case adult = "visitor_details.adult"
    case child = "visitor_details.child"
    case infant = "visitor_details.infant"
    case completed = "visitor_details.completed"
    case incomplete = "visitor_details.incomplete"
    case removeVisitor = "visitor_details.remove_visitor"
    case removeVisitorSheetTitle = "visitor_details.remove_visitor_sheet_title"
    case removeVisitorMessage = "visitor_details.remove_visitor_message"
    case visitorRemoved = "visitor_details.visitor_removed"
    case totalPriceOneVisitor = "static_package_details.total_price_one_visitor"
    case totalPriceVisitors = "static_package_details.total_price_visitors"
    case remove = "common.remove"
    case cancel = "common.cancel"
    case enterFieldPlaceholder = "visitor_details.enter_field_placeholder"
    case selectFieldPlaceholder = "visitor_details.select_field_placeholder"
    case dateOfBirthPlaceholder = "visitor_details.date_placeholder"
    case done = "common.done"

    /// Localized value in the language currently configured in the SDK, independent of the device language.
    @MainActor
    func localized() -> String {
        let language = AlmatarStaticPackageSDK.shared.configuration.language
        return SDKStringsTable.value(for: rawValue, language: language)
    }

    /// Localized format string filled with the given arguments.
    @MainActor
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized(), locale: nil, arguments: arguments)
    }
}

/// Reads the SDK's compiled `Localizable.strings` files directly.
///
/// Host apps may swizzle `Bundle.localizedString(forKey:value:table:)` to force their own
/// language, which redirects every lookup to `Bundle.main` and breaks `NSLocalizedString`,
/// `String(localized:)` and `LocalizedStringKey` for SDK keys. Loading the tables as
/// property lists avoids that method entirely.
@MainActor
private enum SDKStringsTable {
    private enum Constants {
        static let tableName = "Localizable"
        static let fileExtension = "strings"
        static let fallbackLanguage = AppLanguage.english
    }

    private static var cache: [AppLanguage: [String: String]] = [:]

    /// The value in the given language, then in English, then the key itself.
    static func value(for key: String, language: AppLanguage) -> String {
        table(for: language)[key]
            ?? table(for: Constants.fallbackLanguage)[key]
            ?? key
    }

    private static func table(for language: AppLanguage) -> [String: String] {
        if let cached = cache[language] { return cached }
        let table = loadTable(for: language)
        cache[language] = table
        return table
    }

    private static func loadTable(for language: AppLanguage) -> [String: String] {
        guard let url = Bundle.module.url(
                forResource: Constants.tableName,
                withExtension: Constants.fileExtension,
                subdirectory: nil,
                localization: language.rawValue
              ),
              let data = try? Data(contentsOf: url),
              let table = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
            return [:]
        }
        return table
    }
}
