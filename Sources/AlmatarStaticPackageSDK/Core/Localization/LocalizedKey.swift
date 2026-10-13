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

    // MARK: Common
    case genericError = "common.generic_error"
    case retry = "common.retry"

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
