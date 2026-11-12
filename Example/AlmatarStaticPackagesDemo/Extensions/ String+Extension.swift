//
//  File.swift
//  MyApp
//
//  Created by mahmoud ismail on 11/10/2026.
//


//
//  String+Extension.swift
//  Almtaar
//
//  Created by Reem Hesham on 7/2/18.
//  Copyright © 2018 Moustafa Mohamed. All rights reserved.
//

import UIKit

public extension Bundle {
    
    static var almatarFontsBundle: Bundle {
        return .main
    }
}
 
private final class BundleToken {
    static var bundle: Bundle {
        Bundle(for: BundleToken.self)
    }
}

extension String {
    static var localizedTableName: String {
        return "Localizable"
    }
       static var fontTableName: String {
        return "AlmatarFonts"
    }
    
    /**
     localized return the localized value of the current string depending on the current selected app language.
     if there is no langauge selected yet, use a default value
     */
    var localized: String {
        return self
    }

   

    var localizedFont: String {
        return NSLocalizedString(self, tableName: Self.fontTableName, bundle: .almatarFontsBundle, comment: "")
    }
    
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
    
    func getAsDate(_ format: String = "MMM dd yyyy hh:mma", inGMT: Bool = false ) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        if inGMT {
            dateFormatter.timeZone = TimeZone(identifier: "GMT")
        }
        dateFormatter.locale = Locale(identifier: "en_US")
        let date = dateFormatter.date(from: self)
        return  date
    }
    func getAsEnglishDate(fromFormat: String = "yyyy-MM-dd", toFormat: String = "yyyy-MM-dd", inGMT: Bool = false) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: self) {
            formatter.locale = Locale(identifier: "en")
            formatter.dateFormat = "EEEE, d, MMMM, yyyy HH:mm a"
            if inGMT {
                formatter.timeZone = TimeZone(identifier: "GMT")
            }
            let outputDate = formatter.string(from: date)
            return outputDate
        }
        return nil
    }
    
    func getUpdatedDate(addingDays daysToAdd: Int) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = TimeZone(identifier: "GMT")
        dateFormatter.locale = Locale(identifier: "en")
        // Convert String to Date
        guard let baseDate = dateFormatter.date(from: self) else { return nil }
        
        // Add days to the date
        let newDate = Calendar.current.date(byAdding: .day, value: daysToAdd, to: baseDate)
        
        // Convert back to String
        return newDate.map { dateFormatter.string(from: $0) }
    }
    
    func hasMoreThanTwoRepeatedCharactersWithNoLeadingOrTrailingSpaces() -> Bool {
        if hasSuffix(" ") || hasPrefix(" ") {
            return false
        }
        let numberOfDistinctChars = Set(self).count // 2 (Set(String) replacing Set(String.characters))
        if numberOfDistinctChars > 1 {
            return true
        }
        return false
    }
    
    func contains(_ find: String) -> Bool {
        return self.range(of: find) != nil
    }
    
    func containsIgnoringCase(_ find: String) -> Bool {
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    
    public var replacedArabicDigitsWithEnglish: String {
        var str = self
        let map = ["٠": "0",
                   "١": "1",
                   "٢": "2",
                   "٣": "3",
                   "٤": "4",
                   "٥": "5",
                   "٦": "6",
                   "٧": "7",
                   "٨": "8",
                   "٩": "9"]
        map.forEach { str = str.replacingOccurrences(of: $0, with: $1) }
        return str
    }
    
    //Matching regex
    func matching(regex: String) -> Bool {
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: self)
    }
    
    func removeDoubleCurlyBraces() -> String {
        return self.replacingOccurrences(of: "{{", with: "").replacingOccurrences(of: "}}", with: "")
    }
    
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
    
    func htmlAttributedString(alignment: NSTextAlignment = .left) -> NSMutableAttributedString? {
        var stringCopy = self
        if alignment == .right {
            stringCopy = "<div style=\"direction:rtl; text-align: right\"> \(self) </div>"
        }
        guard let data = stringCopy.data(using: .utf8) else {
            return nil
        }
        
        do {
            let attributedString = try NSMutableAttributedString(
                data: data,
                options: [.documentType: NSMutableAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue],
                documentAttributes: nil
            )
            return attributedString
        } catch {
            return nil
        }
    }
    
    func htmlToBullets() -> String {
        self
            .replacingOccurrences(of: "<li>", with: "• ")
            .replacingOccurrences(of: "</li>", with: "<br>")
    }
    
    func stripHTMLTags() -> String {
        return self.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
    
    func height(constraintedWidth width: CGFloat, font: UIFont, spaceBetweenLine: CGFloat? = nil) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin,
                                            attributes: [NSAttributedString.Key.font: font], context: nil)
        
        guard let spaceHeight = spaceBetweenLine else {
            return boundingBox.height
        }
        return boundingBox.height + spaceHeight //(boundingBox.height + (spaceHeight * (width / boundingBox.height)))
    }
    
    func applyStrikethroughStyle(usingDelimiter delimiter: Character) -> NSAttributedString? {
        //        let pattern = "~([^~]+)~"
        let pattern = "\(delimiter)([^\(delimiter)])+\(delimiter)"
        
        // Create a regular expression object
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        
        // Find matches in the input string
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        if matches.count == 0 {
            return nil
        }
        // Create an NSMutableAttributedString to apply strikethrough style
        let attributedString = NSMutableAttributedString(string: self)
        
        // Iterate through matches in reverse order to avoid changing indices
        for match in matches.reversed() {
            // Extract the matched text
            if let range = Range(match.range(at: 0), in: self) {
                let substring = self[range]
                
                // Remove curly braces
                let strippedSubstring = String(substring).replacingOccurrences(of: String(delimiter), with: "")
                
                // Apply strikethrough style to the stripped text
                let strikethroughAttribute: [NSAttributedString.Key: Any] = [
                    NSAttributedString.Key.strikethroughStyle: NSUnderlineStyle.single.rawValue
                ]
                // Convert String.Index to Int for NSRange
                let startIndex = self.distance(from: self.startIndex, to: range.lowerBound)
                let endIndex = self.distance(from: self.startIndex, to: range.upperBound)
                
                attributedString.setAttributes(strikethroughAttribute, range: NSRange(location: startIndex, length: strippedSubstring.count))
                
                // Replace the matched text with the stripped text
                attributedString.replaceCharacters(in: NSRange(location: startIndex, length: endIndex - startIndex), with: strippedSubstring)
                return attributedString
            }
        }
        return nil
    }
    
    func underline() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle,
                                      value: NSUnderlineStyle.single.rawValue,
                                      range: NSRange(location: 0, length: attributedString.length))
        return attributedString
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        guard !isEmpty else { return "" }
        return prefix(1).capitalized + dropFirst()
    }
}

extension String {
    func getValidUrl () -> URL? {
        if let encodedURL = self.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed), let url = URL(string: encodedURL) {
            return url
        } else {
            return nil
        }
    }
    
}

extension String {
    func getAgeFromStringDate() -> Int {
        let now = Date()
        let birthday = self.getAsDate("yyyy-MM-dd") ?? Date()
        let calendar = Calendar.current
        
        let ageComponents = calendar.dateComponents([.year], from: birthday, to: now)
        if let age = ageComponents.year {
            return age
        }
        return 0
    }
}

extension String {
    /// Moves leading punctuation to the end of the string,
    /// fixing badly-encoded RTL strings from backends.
    func fixingLeadingRTLPunctuation() -> String {
        var s = self
        let punctuation: Set<Character> = [".", "،", ",", "!", "؟", "?", ":", ";"]
        while let first = s.first, punctuation.contains(first) {
            s = String(s.dropFirst()) + String(first)
        }
        return s
    }
}

extension String {
    func dateFormateNeglectingTimeZone(formate: String? = "yyyy-MM-dd'T'HH:mm:ss") -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = formate
        return dateFormatter.date(from: self)
    }
    
    func htmlAttributedStringWithMainCustomFont(fontSize: CGFloat, alignment: NSTextAlignment? = nil) -> NSAttributedString? {
        var stringCopy = self
        if let alignment = alignment, alignment == .right {
            stringCopy = "<div style=\"direction:rtl; text-align: right\"> \(self) </div>"
        }
        guard var attributedString = try? NSMutableAttributedString(data: stringCopy.data(using: .utf16) ?? Data(stringCopy.utf8), options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) else {
            return nil
        }
        let range = NSRange(location: 0, length: attributedString.length)
        attributedString.enumerateAttribute(.font, in: range) { value, range, pointer in
            guard let currentFont = value as? UIFont else { return }
            let isBold = currentFont.fontName.lowercased().contains("bold")
            let replacementFont = isBold ? UIFont.myMediumBoldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
            let replacementAttribute = [NSAttributedString.Key.font: replacementFont]
            attributedString.addAttributes(replacementAttribute, range: range)
        }
        
        return attributedString
    }
    
    func minutesAndHoursAndDaysRemaining(dateFormat: String = "yyyy-MM-dd") -> (minute: Int, hours: Int, days: Int)? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = dateFormat
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        guard let targetDate = formatter.date(from: self) else {
            return nil
        }
        
        let today = Date()
        let calendar = Calendar.current
        
        let components = calendar.dateComponents([.minute, .hour, .day], from: today, to: targetDate)
        
        return (components.minute, components.hour, components.day) as? (minute: Int, hours: Int, days: Int)
    }
    
}

extension UILabel {
    var numberOfVisibleLines: Int {
        let maxSize = CGSize(width: frame.size.width, height: CGFloat(MAXFLOAT))
        let textHeight = sizeThatFits(maxSize).height
        let lineHeight = font.lineHeight
        return Int(ceil(textHeight / lineHeight))
    }
}

// MARK: - Apply new price style
extension String {
    
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

extension String {
    func width(usingFont font: UIFont) -> CGFloat {
        let attributes = [NSAttributedString.Key.font: font]
        return (self as NSString).size(withAttributes: attributes).width
    }
    func widthWithDefaultFont() -> CGFloat {
        let attributes = [NSAttributedString.Key.font: UIFont.mySystemFont(ofSize: 12)]
        return (self as NSString).size(withAttributes: attributes).width
    }
}

extension String {
    var containsHTMLTags: Bool {
        // Simple regex for detecting common HTML tags
        return self.range(of: "<[^>]+>", options: .regularExpression) != nil
    }
}

extension String {
    var isEnglishOnly: Bool {
        let englishRange = "^[A-Za-z\\s]+$"
        return NSPredicate(format: "SELF MATCHES %@", englishRange).evaluate(with: self)
    }

    var containsArabicCharacters: Bool {
        range(of: "\\p{Arabic}", options: .regularExpression) != nil
    }

    /// True when the display name matches the current app language.
    var matchesAppLanguage: Bool {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return true }
        return !trimmed.containsArabicCharacters
    }
}

extension String {
    func respectLTRAlignment() -> String {
        return "\u{200E}\(self)"
    }
    
    func respectRTLAlignment() -> String {
        return "\u{200F}\(self)"
    }
}
