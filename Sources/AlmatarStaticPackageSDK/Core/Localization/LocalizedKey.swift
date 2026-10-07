//
//  LocalizedKey.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Keys in `Localizable.xcstrings` (en / ar).
enum LocalizedKey: String {
    // MARK: Static Package Details
    case goToPayment = "static_package_details.go_to_payment"

    // MARK: Common
    case genericError = "common.generic_error"
    case retry = "common.retry"

    /// Localized value in the given SDK language, independent of the device language.
    func localized(_ language: AppLanguage) -> String {
        NSLocalizedString(rawValue, bundle: language.bundle, comment: "")
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
