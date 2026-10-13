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
    case packageSchedule = "static_package_details.package_schedule"
    case includedServices = "static_package_details.included_services"
    case includedServicesSubtitle = "static_package_details.included_services_subtitle"
    case includedInYourPass = "static_package_details.included_in_your_pass"

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
