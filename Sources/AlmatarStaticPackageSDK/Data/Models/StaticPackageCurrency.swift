//
//  StaticPackageCurrency.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// A currency the user can choose, provided by the host app.
/// The JSON keys match the Almatar currency rates response (`base` / `others` items),
/// so the host app can decode them directly or map its own currency model.
public struct StaticPackageCurrency: Codable, Sendable, Hashable, Identifiable {
    /// ISO code, e.g. "SAR".
    public let code: String
    public let name: String?
    public let arabicName: String?
    /// e.g. "SAR".
    public let abbreviation: String?
    /// e.g. "ر.س".
    public let arabicAbbreviation: String?
    /// Rate against the base currency; pass 1 for the base currency (the backend omits it).
    public let rate: Double?
    /// Flag image URL.
    public let logoUrl: String?

    public var id: String { code }

    public init(
        code: String,
        name: String? = nil,
        arabicName: String? = nil,
        abbreviation: String? = nil,
        arabicAbbreviation: String? = nil,
        rate: Double? = nil,
        logoUrl: String? = nil
    ) {
        self.code = code
        self.name = name
        self.arabicName = arabicName
        self.abbreviation = abbreviation
        self.arabicAbbreviation = arabicAbbreviation
        self.rate = rate
        self.logoUrl = logoUrl
    }

    enum CodingKeys: String, CodingKey {
        case code
        case name
        case rate
        case arabicName = "name_ar"
        case abbreviation = "abbrv"
        case arabicAbbreviation = "abbrv_ar"
        case logoUrl = "currencyLogoUrl"
    }

    /// Name in the given language, falling back to the other language, then the code.
    public func displayName(for language: AppLanguage) -> String {
        let preferred = language == .arabic ? arabicName : name
        let fallback = language == .arabic ? name : arabicName
        return preferred.nonEmpty ?? fallback.nonEmpty ?? code
    }

    /// Abbreviation in the given language, e.g. "SAR" or "ر.س", falling back to the code.
    public func displayAbbreviation(for language: AppLanguage) -> String {
        let preferred = language == .arabic ? arabicAbbreviation : abbreviation
        return preferred.nonEmpty ?? code
    }
}
