//
//  VisitorDetailsFormModel.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// State of the "Visitor Details" section built from the backend `DynamicForm`.
/// Values are stored as strings keyed by "section.field" so they can be sent back as-is.
@MainActor
final class VisitorDetailsFormModel: ObservableObject {
    /// How a single form field is rendered.
    enum FieldKind: Equatable {
        /// Short choices shown as pills, e.g. Mr / Ms / Mrs.
        case segmented([DynamicFormOption])
        /// Choices shown in a dropdown, e.g. nationality.
        case dropdown([DynamicFormOption])
        /// Fixed list of dates shown in a dropdown.
        case dateList([DynamicFormDateOption])
        /// Free date, e.g. date of birth.
        case date
        case phone
        case email
        case text
    }

    /// A step in the group counter (adults, children, infants).
    enum Traveller: String, CaseIterable, Identifiable {
        case adults, children, infants
        var id: String { rawValue }
    }

    /// One person in the group; the first adult is the lead visitor.
    struct Visitor: Identifiable, Hashable {
        let id: UUID
        let type: Traveller
    }

    /// Country calling code shown in the phone field.
    struct PhoneCountry: Hashable, Identifiable, Sendable {
        /// ISO 3166 alpha-2 code, used for the flag.
        let code: String
        let dialCode: String
        var id: String { code }
    }

    private enum Constants {
        static let segmentedMaxOptions = 3
        static let segmentedMaxTitleLength = 4
        static let travellersSection = "travellers"
        static let firstNameField = "firstName"
        static let lastNameField = "lastName"
        /// Prefix of the per-visitor section keys, e.g. "travellers#<uuid>".
        static let visitorSectionSeparator = "#"
        static let visitorTypeKey = "type"
        static let maxTravellers = 9
        static let apiDateFormat = "yyyy-MM-dd"
        static let displayDateFormat = "dd/MM/yyyy"
        static let dayMonthTemplate = "d MMM"
        static let monthKeyFormat = "yyyy-MM"
        // Fixed formats, not templates, so both languages read day before month as in the design.
        static let monthYearFormat = "MMMM yyyy"
        static let dayMonthYearFormat = "d MMMM yyyy"
        /// Keeps Latin digits for Arabic dates, as in the design.
        static let latinDigitsSuffix = "@numbers=latn"
        static let rangeDash = " – "
        static let posixLocale = Locale(identifier: "en_US_POSIX")
        static let utc = TimeZone(identifier: "UTC")!
        static let emailPattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        static let minPhoneDigits = 6
    }

    // TODO: Replace with the list from the backend once available.
    nonisolated static let phoneCountries: [PhoneCountry] = [
        PhoneCountry(code: "SA", dialCode: "+966"),
        PhoneCountry(code: "AE", dialCode: "+971"),
        PhoneCountry(code: "KW", dialCode: "+965"),
        PhoneCountry(code: "QA", dialCode: "+974"),
        PhoneCountry(code: "BH", dialCode: "+973"),
        PhoneCountry(code: "OM", dialCode: "+968"),
        PhoneCountry(code: "EG", dialCode: "+20"),
        PhoneCountry(code: "JO", dialCode: "+962")
    ]

    @Published private(set) var form: DynamicForm?
    @Published private var values: [String: String] = [:]
    @Published private var phoneCountryCodes: [String: String] = [:]
    /// The group in the order visitors were added; always starts with the lead adult.
    @Published private(set) var visitors: [Visitor] = [Visitor(id: UUID(), type: .adults)]
    /// Visitor cards that are open; a newly added visitor opens automatically.
    @Published var expandedVisitorIds: Set<UUID> = []

    var title: String { form?.title.nonEmpty ?? LocalizedKey.visitorDetails.localized() }
    var subtitle: String? { form?.subtitle.nonEmpty }
    var sections: [DynamicFormSection] { form?.sections ?? [] }
    var hasContent: Bool { !sections.isEmpty }

    // MARK: - Setup

    /// Resets the state for a new form and preselects the first choice of each picker section.
    func configure(with form: DynamicForm?) {
        self.form = form
        values = [:]
        phoneCountryCodes = [:]
        let lead = Visitor(id: UUID(), type: .adults)
        visitors = [lead]
        expandedVisitorIds = [lead.id]

        for section in form?.sections ?? [] where isPickerSection(section) {
            guard let field = section.fields.first else { continue }
            switch kind(of: field) {
            case .dropdown(let options), .segmented(let options):
                values[key(section, field)] = options.first?.code
            case .dateList(let options):
                values[key(section, field)] = options.first?.date
            default:
                break
            }
        }
    }

    // MARK: - Layout

    /// A section with a single choice field and no title is shown as a collapsed selection row
    /// (e.g. departure city, visit date); every other section is an expandable card.
    func isPickerSection(_ section: DynamicFormSection) -> Bool {
        guard !isTravellersSection(section),
              section.fields.count == 1,
              let field = section.fields.first else { return false }
        switch kind(of: field) {
        case .dropdown, .segmented, .dateList: return true
        default: return false
        }
    }

    func isTravellersSection(_ section: DynamicFormSection) -> Bool {
        section.section == Constants.travellersSection
    }

    func cardTitle(for section: DynamicFormSection) -> String {
        isTravellersSection(section) ? LocalizedKey.visitorsInformation.localized() : (section.title.nonEmpty ?? "")
    }

    func kind(of field: DynamicFormField) -> FieldKind {
        let options = field.options ?? []
        switch field.dataType {
        case .phone:
            return .phone
        case .email:
            return .email
        case .date:
            if let dates = field.dateConfigs?.options, !dates.isEmpty {
                return .dateList(dates)
            }
            return .date
        case .string, .unknown:
            guard !options.isEmpty else { return .text }
            let isShort = options.count <= Constants.segmentedMaxOptions
                && options.allSatisfy { $0.name.count <= Constants.segmentedMaxTitleLength }
            return isShort ? .segmented(options) : .dropdown(options)
        }
    }

    // MARK: - Values

    func key(_ section: DynamicFormSection, _ field: DynamicFormField) -> String {
        "\(section.section).\(field.field)"
    }

    func value(_ section: DynamicFormSection, _ field: DynamicFormField) -> String {
        values[key(section, field)] ?? ""
    }

    func setValue(_ value: String, _ section: DynamicFormSection, _ field: DynamicFormField) {
        values[key(section, field)] = value
    }

    func phoneCountry(_ section: DynamicFormSection, _ field: DynamicFormField) -> PhoneCountry {
        let code = phoneCountryCodes[key(section, field)]
        return Self.phoneCountries.first { $0.code == code } ?? Self.phoneCountries[0]
    }

    func setPhoneCountry(_ country: PhoneCountry, _ section: DynamicFormSection, _ field: DynamicFormField) {
        phoneCountryCodes[key(section, field)] = country.code
    }

    /// Free dates come from the device date picker, so they use the device time zone.
    func date(_ section: DynamicFormSection, _ field: DynamicFormField) -> Date? {
        localDateFormatter(Constants.apiDateFormat).date(from: value(section, field))
    }

    func setDate(_ date: Date, _ section: DynamicFormSection, _ field: DynamicFormField) {
        setValue(localDateFormatter(Constants.apiDateFormat).string(from: date), section, field)
    }

    // MARK: - Display text

    /// Name of the selected option, or the formatted selected date.
    func selectedText(_ section: DynamicFormSection, _ field: DynamicFormField) -> String? {
        let current = value(section, field)
        guard !current.isEmpty else { return nil }
        switch kind(of: field) {
        case .dropdown(let options), .segmented(let options):
            return options.first { $0.code == current }?.name
        case .dateList:
            return apiDateFormatter.date(from: current).map { dayMonthFormatter.string(from: $0) }
        case .date:
            return date(section, field).map { localDateFormatter(Constants.displayDateFormat).string(from: $0) }
        default:
            return current
        }
    }

    /// e.g. "Departure Riyadh" or "Visit Date: 16 Jul".
    func selectionRowTitle(_ section: DynamicFormSection, _ field: DynamicFormField) -> String {
        guard let selected = selectedText(section, field) else { return field.label }
        if case .dateList = kind(of: field) {
            return "\(field.label): \(selected)"
        }
        return "\(field.label) \(selected)"
    }

    /// e.g. "19 Jul – 21 Jul".
    func dateOptionTitle(_ option: DynamicFormDateOption) -> String {
        guard let date = apiDateFormatter.date(from: option.date) else { return option.date }
        var title = dayMonthFormatter.string(from: date)
        if let returnDate = option.returnDate.nonEmpty.flatMap(apiDateFormatter.date(from:)) {
            title += Constants.rangeDash + dayMonthFormatter.string(from: returnDate)
        }
        return title
    }

    // MARK: - Selection sheet

    func isDateList(_ field: DynamicFormField) -> Bool {
        if case .dateList = kind(of: field) { return true }
        return false
    }

    /// e.g. "Select Your Visit Date", or the field label for other choices.
    func selectionSheetTitle(_ field: DynamicFormField) -> String {
        isDateList(field) ? LocalizedKey.selectVisitDate.localized() : field.label
    }

    /// Dates grouped by month in API order, e.g. "July 2026 · 2 Available".
    func dateSheetSections(_ options: [DynamicFormDateOption]) -> [SelectionSheetSection<DynamicFormDateOption>] {
        var groups: [(key: String, date: Date, items: [DynamicFormDateOption])] = []
        let monthKey = apiFormatter(Constants.monthKeyFormat)
        for option in options {
            guard let date = apiDateFormatter.date(from: option.date) else { continue }
            let key = monthKey.string(from: date)
            if let index = groups.firstIndex(where: { $0.key == key }) {
                groups[index].items.append(option)
            } else {
                groups.append((key, date, [option]))
            }
        }
        let monthYear = displayFormatter(Constants.monthYearFormat)
        return groups.map { group in
            SelectionSheetSection(
                id: group.key,
                title: monthYear.string(from: group.date),
                caption: LocalizedKey.availableCount.localized(with: group.items.count),
                items: group.items
            )
        }
    }

    /// One untitled section holding every option, e.g. departure cities.
    func optionSheetSections(_ options: [DynamicFormOption]) -> [SelectionSheetSection<DynamicFormOption>] {
        [SelectionSheetSection(id: "options", title: nil, caption: nil, items: options)]
    }

    /// e.g. "Sunday, 19 July".
    func dateOptionDayTitle(_ option: DynamicFormDateOption) -> String {
        guard let date = apiDateFormatter.date(from: option.date) else { return option.date }
        // The format is localized so each language uses its own comma.
        return displayFormatter(LocalizedKey.weekdayDayMonthFormat.localized()).string(from: date)
    }

    /// e.g. "21 July 2026"; `nil` when the option has no return date.
    func returnDateText(_ option: DynamicFormDateOption) -> String? {
        guard let date = option.returnDate.nonEmpty.flatMap(apiDateFormatter.date(from:)) else { return nil }
        return displayFormatter(Constants.dayMonthYearFormat).string(from: date)
    }

    func selectedDateOption(_ section: DynamicFormSection, _ field: DynamicFormField) -> DynamicFormDateOption? {
        guard case .dateList(let options) = kind(of: field) else { return nil }
        let current = value(section, field)
        return options.first { $0.date == current }
    }

    func selectedOption(_ section: DynamicFormSection, _ field: DynamicFormField) -> DynamicFormOption? {
        let current = value(section, field)
        switch kind(of: field) {
        case .dropdown(let options), .segmented(let options):
            return options.first { $0.code == current }
        default:
            return nil
        }
    }

    /// Flag emoji for an ISO country code; `nil` when the code is not two letters.
    nonisolated static func flag(for code: String) -> String? {
        let letters = code.uppercased().unicodeScalars
        guard letters.count == 2, letters.allSatisfy({ $0.value >= 65 && $0.value <= 90 }) else { return nil }
        let flag = letters.compactMap { UnicodeScalar(127_397 + $0.value) }.map(String.init).joined()
        return flag
    }

    // MARK: - Visitors

    var travellersSection: DynamicFormSection? {
        sections.first(where: isTravellersSection)
    }

    func isLead(_ visitor: Visitor) -> Bool {
        visitor.id == visitors.first?.id
    }

    /// The visitor's own copy of the travellers fields. Values are stored under its own section key,
    /// so every field control works per visitor. Contact fields are asked of the lead visitor only.
    func section(for visitor: Visitor) -> DynamicFormSection? {
        guard let travellers = travellersSection else { return nil }
        let fields = isLead(visitor) ? travellers.fields : travellers.fields.filter { !isContactField($0) }
        return DynamicFormSection(
            section: Constants.travellersSection + Constants.visitorSectionSeparator + visitor.id.uuidString,
            title: nil,
            fields: fields
        )
    }

    /// Full name once entered, otherwise e.g. "Adult 2".
    func displayName(_ visitor: Visitor) -> String {
        if let section = section(for: visitor) {
            let name = [Constants.firstNameField, Constants.lastNameField]
                .compactMap { key in section.fields.first { $0.field == key } }
                .map { value(section, $0).trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            if !name.isEmpty { return name }
        }
        let position = visitors.filter { $0.type == visitor.type }.firstIndex(of: visitor).map { $0 + 1 } ?? 1
        return "\(visitor.type.singularTitle) \(position)"
    }

    /// "Lead visitor", or e.g. "Visitor 2".
    func roleTitle(_ visitor: Visitor) -> String {
        isLead(visitor) ? LocalizedKey.leadVisitor.localized() : visitorNumberTitle(visitor)
    }

    /// e.g. "Visitor 2", by position in the whole group.
    func visitorNumberTitle(_ visitor: Visitor) -> String {
        let number = (visitors.firstIndex(of: visitor) ?? 0) + 1
        return LocalizedKey.visitorNumber.localized(with: number)
    }

    func isComplete(_ visitor: Visitor) -> Bool {
        guard let section = section(for: visitor) else { return false }
        return section.fields.allSatisfy { isFieldValid($0, in: section) }
    }

    func isExpanded(_ visitor: Visitor) -> Bool {
        expandedVisitorIds.contains(visitor.id)
    }

    func toggleExpanded(_ visitor: Visitor) {
        if expandedVisitorIds.contains(visitor.id) {
            expandedVisitorIds.remove(visitor.id)
        } else {
            expandedVisitorIds.insert(visitor.id)
        }
    }

    /// Every visitor except the lead can be removed.
    func canRemove(_ visitor: Visitor) -> Bool {
        !isLead(visitor) && visitors.contains(visitor)
    }

    /// Removes the visitor and their entered details.
    func remove(_ visitor: Visitor) {
        guard canRemove(visitor) else { return }
        delete([visitor])
        dropInfantsAboveAdults()
    }

    private func isContactField(_ field: DynamicFormField) -> Bool {
        switch kind(of: field) {
        case .phone, .email: return true
        default: return false
        }
    }

    private func delete(_ removed: [Visitor]) {
        let ids = Set(removed.map(\.id))
        let prefixes = removed.compactMap { section(for: $0)?.section }.map { $0 + "." }
        visitors.removeAll { ids.contains($0.id) }
        expandedVisitorIds.subtract(ids)
        values = values.filter { key, _ in !prefixes.contains { key.hasPrefix($0) } }
        phoneCountryCodes = phoneCountryCodes.filter { key, _ in !prefixes.contains { key.hasPrefix($0) } }
    }

    /// One infant per adult: removing adults also removes the last extra infants.
    private func dropInfantsAboveAdults() {
        let extra = count(.infants) - count(.adults)
        guard extra > 0 else { return }
        delete(Array(visitors.filter { $0.type == .infants }.suffix(extra)))
    }

    // MARK: - Counters

    func count(_ traveller: Traveller) -> Int {
        visitors.filter { $0.type == traveller }.count
    }

    /// The visitor the counter's minus button removes: the last one of that type, never the lead.
    func lastRemovableVisitor(of traveller: Traveller) -> Visitor? {
        guard let last = visitors.last(where: { $0.type == traveller }), canRemove(last) else { return nil }
        return last
    }

    func canDecrement(_ traveller: Traveller) -> Bool {
        lastRemovableVisitor(of: traveller) != nil
    }

    func canIncrement(_ traveller: Traveller) -> Bool {
        switch traveller {
        case .infants:
            // One infant per adult.
            return count(.infants) < count(.adults)
        case .adults, .children:
            return count(.adults) + count(.children) < Constants.maxTravellers
        }
    }

    /// Adds a visitor of the given type and opens their card.
    func increment(_ traveller: Traveller) {
        guard canIncrement(traveller) else { return }
        let visitor = Visitor(id: UUID(), type: traveller)
        visitors.append(visitor)
        expandedVisitorIds.insert(visitor.id)
    }

    // MARK: - Validation & output

    /// `true` when every required field has a valid value, for every visitor.
    var isValid: Bool {
        let otherSectionsValid = sections.filter { !isTravellersSection($0) }.allSatisfy { section in
            section.fields.allSatisfy { isFieldValid($0, in: section) }
        }
        return otherSectionsValid && visitors.allSatisfy(isComplete)
    }

    func isFieldValid(_ field: DynamicFormField, in section: DynamicFormSection) -> Bool {
        let current = value(section, field).trimmingCharacters(in: .whitespacesAndNewlines)
        if current.isEmpty { return !field.required }
        switch kind(of: field) {
        case .email:
            return current.range(of: Constants.emailPattern, options: .regularExpression) != nil
        case .phone:
            return current.filter(\.isNumber).count >= Constants.minPhoneDigits
        default:
            return true
        }
    }

    /// Values keyed by field, grouped by section (travellers excluded, see `visitorSubmissions`);
    /// phone numbers include the dial code.
    var submissionValues: [String: [String: String]] {
        var result: [String: [String: String]] = [:]
        for section in sections where !isTravellersSection(section) {
            result[section.section] = fieldValues(section)
        }
        return result
    }

    /// One entry per visitor in group order, with its type, e.g. `["type": "adults", "firstName": ...]`.
    var visitorSubmissions: [[String: String]] {
        visitors.compactMap { visitor in
            guard let section = section(for: visitor) else { return nil }
            var entry = fieldValues(section)
            entry[Constants.visitorTypeKey] = visitor.type.rawValue
            return entry
        }
    }

    private func fieldValues(_ section: DynamicFormSection) -> [String: String] {
        var result: [String: String] = [:]
        for field in section.fields {
            let current = value(section, field)
            guard !current.isEmpty else { continue }
            if case .phone = kind(of: field) {
                result[field.field] = phoneCountry(section, field).dialCode + current.filter(\.isNumber)
            } else {
                result[field.field] = current
            }
        }
        return result
    }

    // MARK: - Formatting

    private var displayLocale: Locale {
        Locale(identifier: AlmatarStaticPackageSDK.shared.configuration.language.rawValue + Constants.latinDigitsSuffix)
    }

    private func apiFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Constants.posixLocale
        formatter.timeZone = Constants.utc
        formatter.dateFormat = format
        return formatter
    }

    /// Localized month and weekday names in UTC, matching how API dates are parsed.
    private func displayFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = displayLocale
        formatter.timeZone = Constants.utc
        formatter.dateFormat = format
        return formatter
    }

    private var apiDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Constants.posixLocale
        formatter.timeZone = Constants.utc
        formatter.dateFormat = Constants.apiDateFormat
        return formatter
    }

    private var dayMonthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = displayLocale
        formatter.timeZone = Constants.utc
        formatter.setLocalizedDateFormatFromTemplate(Constants.dayMonthTemplate)
        return formatter
    }

    private func localDateFormatter(_ format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Constants.posixLocale
        formatter.timeZone = .current
        formatter.dateFormat = format
        return formatter
    }
}

// MARK: - Traveller strings

extension VisitorDetailsFormModel.Traveller {
    /// e.g. "Adult", used in "Adult 2".
    @MainActor
    var singularTitle: String {
        switch self {
        case .adults: return LocalizedKey.adult.localized()
        case .children: return LocalizedKey.child.localized()
        case .infants: return LocalizedKey.infant.localized()
        }
    }
}
