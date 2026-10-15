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
    case cancellationFree = "static_package_details.cancellation_free"
    case cancellationPartialRefund = "static_package_details.cancellation_partial_refund"
    case cancellationNonRefundable = "static_package_details.cancellation_non_refundable"

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
