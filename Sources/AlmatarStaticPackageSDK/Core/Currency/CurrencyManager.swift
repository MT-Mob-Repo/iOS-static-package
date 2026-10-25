//
//  CurrencyManager.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Converts and formats prices, mirroring the Almatar app's `CurrencyManager`.
/// The selected currency and the currency list come from the SDK configuration
/// (`currency` and `availableCurrencies`), which the host app keeps up to date.
@MainActor
final class CurrencyManager {
    static let shared = CurrencyManager()
    static let noPriceString = "-"

    private let defaultCurrencyCode = StaticPackageConfiguration.defaultCurrency
    /// Currencies shown with two decimals instead of being rounded up.
    private let supportedCurrencies: [String] = ["OMR", "KWD", "BHD"]

    private init() {}

    // MARK: - Configuration

    private var configuration: StaticPackageConfiguration {
        AlmatarStaticPackageSDK.shared.configuration
    }

    private var isArabic: Bool {
        configuration.language == .arabic
    }

    /// Every currency the user can choose, base currency first.
    var currencies: [StaticPackageCurrency] {
        configuration.availableCurrencies
    }

    /// The selected currency, or the base currency when the selection is not in the list.
    var currentSelectedCurrency: StaticPackageCurrency {
        currency(for: configuration.currency) ?? baseCurrency
    }

    // MARK: - Base currency

    var baseCurrency: StaticPackageCurrency {
        defaultCurrency
    }

    var defaultCurrency: StaticPackageCurrency {
        StaticPackageCurrency(
            code: defaultCurrencyCode,
            name: "Saudian Riyal",
            arabicName: "ريال سعودي",
            abbreviation: defaultCurrencyCode,
            arabicAbbreviation: defaultCurrencyCode,
            rate: 1
        )
    }

    var baseCurrencyCode: String {
        baseCurrency.code
    }

    var isBaseCurrencySameAsDefaultCurrency: Bool {
        currentSelectedCurrency.code == defaultCurrencyCode
    }

    var baseCurrencyName: String {
        abbreviation(of: baseCurrency) ?? ""
    }

    /// Abbreviation of the selected currency in the SDK language, e.g. "SAR".
    var currencyName: String {
        currency(for: configuration.currency).flatMap(abbreviation(of:)) ?? defaultCurrencyCode
    }

    // MARK: - Formatting

    /// e.g. "1,250 USD": `value` in `currencyCode` (base currency by default) converted to `toCurrency`,
    /// else to the selected currency. Rounded up unless the selected currency shows decimals.
    func formatPrice(
        value: Any?,
        currencyCode: String? = nil,
        toCurrency: String? = nil,
        isRounded: Bool = true,
        rule: FloatingPointRoundingRule? = .up
    ) -> String {
        let isRounded = isCurrentCurrencySupported() ? false : isRounded
        if let amount = value as? Int {
            return formatPrice(value: Double(amount), currencyCode: currencyCode, toCurrency: toCurrency, isRounded: isRounded, rule: rule)
        } else if let amount = value as? Float {
            return formatPrice(value: Double(amount), currencyCode: currencyCode, toCurrency: toCurrency, isRounded: isRounded, rule: rule)
        } else if let amount = value as? Double {
            return formatPrice(value: amount, currencyCode: currencyCode, toCurrency: toCurrency, isRounded: isRounded, rule: rule)
        } else if let amount = value as? Decimal {
            return formatPrice(value: NSDecimalNumber(decimal: amount).doubleValue, currencyCode: currencyCode, toCurrency: toCurrency, isRounded: isRounded, rule: rule)
        } else {
            return Self.noPriceString
        }
    }

    /// e.g. "1,250 SAR": `value` multiplied by `roe` (rate of exchange), with the given currency code.
    func formatPrice(value: Double?, currency: String?, roe: Double? = nil, hasFraction: Bool = false) -> String {
        guard let value else { return Self.noPriceString }
        var finalAmount = value * (roe ?? 1)
        if !hasFraction { finalAmount.round(.up) }
        let stringAmount = decimalFormattedAmount(amount: finalAmount, allowedFractionNumber: hasFraction ? 2 : 0)
        return "\(stringAmount) \(currency ?? baseCurrencyCode)"
    }

    func convert(value: Double, from: StaticPackageCurrency, to: StaticPackageCurrency, isRounded: Bool = true) -> Double {
        let isRounded = isCurrentCurrencySupported() ? false : isRounded
        let convertedAmount = createPrice(value: value, currencyCode: from.code).price(for: to).amount
        return isRounded ? convertedAmount.rounded(.up) : convertedAmount
    }

    /// e.g. "1,250" or "1,250.50"; always with English digits and grouping.
    func decimalFormattedAmount(amount: Any, allowedFractionNumber: Int? = nil) -> String {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        formatter.locale = Locale(identifier: "en")
        if let allowedFractionNumber, allowedFractionNumber > 0 {
            formatter.alwaysShowsDecimalSeparator = true
            formatter.minimumFractionDigits = allowedFractionNumber
            formatter.maximumFractionDigits = allowedFractionNumber
        } else {
            formatter.alwaysShowsDecimalSeparator = false
        }

        let number: NSNumber?
        switch amount {
        case let value as Int: number = NSNumber(value: value)
        case let value as Double: number = NSNumber(value: value)
        case let value as Float: number = NSNumber(value: value)
        case let value as Decimal: number = NSDecimalNumber(decimal: value)
        default: number = nil
        }
        return number.flatMap { formatter.string(from: $0) } ?? ""
    }

    func isCurrentCurrencySupported() -> Bool {
        supportedCurrencies.contains(currentSelectedCurrency.code)
    }

    // MARK: - Helpers

    func abbreviation(of currency: StaticPackageCurrency) -> String? {
        isArabic ? currency.arabicAbbreviation : currency.abbreviation
    }

    private func currency(for code: String?) -> StaticPackageCurrency? {
        guard let code else { return nil }
        return currencies.first { $0.code.caseInsensitiveCompare(code) == .orderedSame }
    }

    private func createPrice(value: Double, currencyCode: String? = nil) -> Price {
        // A code that is not in the list is treated as the base currency.
        let currency = currency(for: currencyCode ?? baseCurrencyCode) ?? baseCurrency
        return Price(amount: value, currency: currency)
    }

    private func formatPrice(
        value: Double?,
        currencyCode: String? = nil,
        toCurrency: String? = nil,
        isRounded: Bool = true,
        rule: FloatingPointRoundingRule? = .up
    ) -> String {
        let isRounded = isCurrentCurrencySupported() ? false : isRounded
        guard let amount = value else { return Self.noPriceString }

        let price = createPrice(value: amount, currencyCode: currencyCode)
        // Same order as the Almatar app: the requested currency, then the selected one,
        // else the amount stays in its own currency.
        let target = toCurrency.flatMap { code in
            currency(for: code) ?? (code == baseCurrencyCode ? baseCurrency : nil)
        } ?? currency(for: configuration.currency)
        let converted = target.map { price.price(for: $0) } ?? price
        return isRounded ? converted.string(rounded: rule) : converted.stringWithTwoFraction()
    }
}

// MARK: - Price
struct Price {
    var amount: Double
    let currency: StaticPackageCurrency
    
    func price(for newCurrency: StaticPackageCurrency) -> Price {
        guard let rate = currency.rate, let newRate = newCurrency.rate else {
            // assume rate = 1
            return Price(amount: amount, currency: newCurrency)
        }
        let newAmount = amount / rate * newRate
        return Price(amount: newAmount, currency: newCurrency)
    }
}

extension Price {
    @MainActor func string(rounded rule: FloatingPointRoundingRule?) -> String {
        var value: Int
        if let rule = rule {
            value = Int(amount.rounded(rule))
        } else {
            value = Int(amount.rounded())
        }
        let name = AlmatarStaticPackageSDK.shared.configuration.language.isRTL ? currency.arabicAbbreviation : currency.abbreviation
        return "\(CurrencyManager.shared.decimalFormattedAmount(amount: value)) \(name ?? "")"
    }
    
    @MainActor func stringWithTwoFraction() -> String {
        let name = AlmatarStaticPackageSDK.shared.configuration.language.isRTL ? currency.arabicAbbreviation : currency.abbreviation
        return "\(CurrencyManager.shared.decimalFormattedAmount(amount: amount, allowedFractionNumber: 2)) \(name ?? "")"
    }
}
