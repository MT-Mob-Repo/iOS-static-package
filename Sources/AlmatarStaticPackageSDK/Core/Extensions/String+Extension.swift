//
//  String+Extension.swift
//  AlmatarStaticPackageSDK
//
//  Created by mahmoud ismail on 20/10/2026.
//
import UIKit

// MARK: - Apply new price style
extension String {
    
    // Apply strike font on text
    // testUILabel.attributedText = "text".strikeThrough()
    func strikeThrough() -> NSAttributedString {
        guard self.isEmpty || self == "-" else {
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: self)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSMakeRange(0, attributeString.length))
            return attributeString
        }
         return NSAttributedString(string: "")
    }
       
    @MainActor func getPriceBeforeFormat(font: UIFont?, alignment: NSTextAlignment = .natural) -> NSAttributedString {
        guard self.isEmpty || self == "-" else {
            if let font = font {
                let attributeString = self.getNewPriceFormat(fontName: font.fontName, fontSize: font.pointSize)
                let mutableAttributedString = NSMutableAttributedString(attributedString: attributeString)
                mutableAttributedString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: .zero, length: mutableAttributedString.length))
                return mutableAttributedString
            }
            return self.strikeThrough()
        }
        return NSAttributedString(string: "")
    }
    
    /// `true` when the string contains at least one Arabic-script scalar.
    var containsArabicCharacters: Bool {
        unicodeScalars.contains { scalar in
            (0x0600...0x06FF).contains(scalar.value) || // Arabic
            (0x0750...0x077F).contains(scalar.value) || // Arabic Supplement
            (0x08A0...0x08FF).contains(scalar.value) || // Arabic Extended-A
            (0xFB50...0xFDFF).contains(scalar.value) || // Arabic Presentation Forms-A
            (0xFE70...0xFEFF).contains(scalar.value)    // Arabic Presentation Forms-B
        }
    }

    /// `true` when every character is a digit (Latin or Arabic-Indic) or a
    /// numeric symbol (% ٪ . , + -), i.e. the token carries no Arabic letters.
    var isNumericToken: Bool {
        guard !isEmpty else { return false }
        let allowed = CharacterSet(charactersIn: "0123456789٠١٢٣٤٥٦٧٨٩%٪.,+-")
        return unicodeScalars.allSatisfy { allowed.contains($0) }
    }

    /// No-op for non-Arabic text or when the first token isn't purely numeric.
    func movingLeadingNumberToEndForArabic() -> String {
        guard containsArabicCharacters else { return self }
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        var tokens = trimmed.components(separatedBy: " ").filter { !$0.isEmpty }
        guard tokens.count > 1, let first = tokens.first, first.isNumericToken else {
            return self
        }
        tokens.removeFirst()
        tokens.append("\u{200F}\(first)\u{200F}")
        return tokens.joined(separator: " ")
    }

    @MainActor func getNewPriceFormat(fontName: String? = nil, fontSize: CGFloat = .zero, alignment: NSTextAlignment = .natural, handleArabic: Bool = false) -> NSAttributedString {
        let newCurrencyFormatString = forceCurrencySymbolPositionToTheLeft()
        let attributedString = NSMutableAttributedString(string: newCurrencyFormatString)
        let paragraphStyle = NSMutableParagraphStyle()
        if handleArabic {
            paragraphStyle.baseWritingDirection = AlmatarStaticPackageSDK.shared.configuration.language.isRTL ? .rightToLeft : .leftToRight
        }
        paragraphStyle.alignment = alignment
        if let fontName = fontName, let font = UIFont(name: fontName, size: fontSize) {
            attributedString.addAttribute(.font, value: font, range: NSRange(location: .zero, length: newCurrencyFormatString.count))
            attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: .zero, length: newCurrencyFormatString.count))
        }
        
        // Find the ranges of the substring (SAR)
        let sarRanges = newCurrencyFormatString.findAllRanges(value: "SAR")
        let minRequiredFontSize: CGFloat = fontSize < 14 ? 14 : fontSize
        if let font = UIFont(name: "sarRegular".localized, size: minRequiredFontSize), !sarRanges.isEmpty {
            for range in sarRanges {
                let nsRange = NSRange(range, in: newCurrencyFormatString)
                attributedString.addAttribute(.font, value: font, range: nsRange)
                attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: nsRange)
            }
        }
        
        return attributedString
    }
    
    func isStringValidNumber(_ input: String) -> Bool {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .init(identifier: "en")
        if formatter.number(from: input) != nil {
            return true
        } else {
            return false
        }
    }
    
    @MainActor private func forceCurrencySymbolPositionToTheLeft() -> String {
        let allSARCurrencySymbols = ["SAR", "SR", "ريال", "ر.س", "ر. س."]
        let currencies = CurrencyManager.shared.currencies.map{ $0.code }
        var components = self.components(separatedBy: " ")
        for index in 1..<components.count {
            let previousIndex = index - 1
            guard let previousItem = components[safe: previousIndex] else { continue }
            if let item = components[safe: index], allSARCurrencySymbols.contains(item) {
                if isStringValidNumber(previousItem) || isNumberWithPrefixPlus(previousItem) {
                    components[previousIndex] = "SAR"
                    components[index] = previousItem
                }
            } else if let item = components[safe: index], allSARCurrencySymbols.contains(String(item.dropLast())), isTheLastCharacterSpecial(item) {
                if isStringValidNumber(previousItem) || isNumberWithPrefixPlus(previousItem) {
                    let lastCharacter = item.last ?? Character("")
                    components[previousIndex] = "SAR"
                    components[index] = previousItem + String(lastCharacter)
                }
            } else if let item = components[safe: index], currencies.contains(item) {
                if isStringValidNumber(previousItem) || isNumberWithPrefixPlus(previousItem) {
                    components[previousIndex] = item
                    components[index] = previousItem
                }
            } else if let item = components[safe: index], currencies.contains(String(item.dropLast())), isTheLastCharacterSpecial(item) {
                if isStringValidNumber(previousItem) || isNumberWithPrefixPlus(previousItem) {
                    let lastCharacter = item.last ?? Character("")
                    components[previousIndex] = String(item.dropLast())
                    components[index] = previousItem + String(lastCharacter)
                }
            }
        }
        let result = components.joined(separator: " ")
        return result
    }
    
    private func isTheLastCharacterSpecial(_ text: String) -> Bool {
        return (text.hasSuffix(".") || text.hasSuffix(",") || text.hasSuffix("،"))
    }
    
    private func isNumberWithPrefixPlus(_ text: String) -> Bool {
        guard text.count > 1 else { return false }
        let textHasPrefixMinusOrPlus = text.hasPrefix("+") || text.hasPrefix("-")
        if textHasPrefixMinusOrPlus && isStringValidNumber(String(text.dropFirst())) {
            return true
        } else {
            return false
        }
    }

    private func findAllRanges(value: String) -> [Range<String.Index>] {
        var searchRange = self.startIndex..<self.endIndex
        var ranges: [Range<String.Index>] = []

        while let range = self.range(of: value, options: .literal, range: searchRange) {
            ranges.append(range)
            searchRange = range.upperBound..<self.endIndex
        }
        return ranges
    }
}
