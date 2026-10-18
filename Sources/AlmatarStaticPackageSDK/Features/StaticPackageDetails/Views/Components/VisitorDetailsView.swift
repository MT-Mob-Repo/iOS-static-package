//
//  VisitorDetailsView.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI
import AlmatarSystemDesignSDK

struct VisitorDetailsView: View {
    private enum Layout {
        static let borderWidth: CGFloat = 1
        static let rowIconSize: CGFloat = 16
        static let chevronSize: CGFloat = 12
        static let inputHeight: CGFloat = 48
        static let pillHeight: CGFloat = 28
        static let counterButtonSize: CGFloat = 28
        static let counterIconSize: CGFloat = 12
        static let counterValueWidth: CGFloat = 24
        static let disabledOpacity: Double = 0.4
        static let datePickerHeight: CGFloat = 300
        static let defaultBirthYearsAgo = -25
        static let departureIcon = "mappin.and.ellipse"
        static let dateIcon = "calendar"
        static let groupIcon = "person.2"
        static let forwardChevron = "chevron.forward"
        static let downChevron = "chevron.down"
        static let upChevron = "chevron.up"
        static let minusIcon = "minus"
        static let plusIcon = "plus"
        // TODO: Replace with the design-system "on primary" text color once available.
        static let selectedPillText = Color.white
    }

    /// The free-date field whose picker sheet is open.
    private struct DateTarget: Identifiable {
        let section: DynamicFormSection
        let field: DynamicFormField
        var id: String { "\(section.section).\(field.field)" }
    }

    @ObservedObject var form: VisitorDetailsFormModel

    /// Expandable cards start open.
    @State private var collapsedSections: Set<String> = []
    @State private var dateTarget: DateTarget?
    @State private var pickerDate = Date()

    private let leadGuestTitle = LocalizedKey.leadGuestDetails.localized()
    private let selectTitle = LocalizedKey.select.localized()
    private let doneTitle = LocalizedKey.done.localized()

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xxSmall) {
                Text(form.title)
                    .modifier(AppTextModifier(size: Typography.Size.large, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                if let subtitle = form.subtitle {
                    Text(subtitle)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textSecondaryStatic)
                }
            }

            VStack(spacing: Spacing.small) {
                ForEach(form.sections) { section in
                    if form.isPickerSection(section), let field = section.fields.first {
                        selectionRow(section, field)
                    } else {
                        sectionCard(section)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $dateTarget) { target in
            datePickerSheet(target)
        }
    }

    // MARK: - Selection row

    /// Collapsed row that opens a menu with the field's choices, e.g. "Departure Riyadh".
    private func selectionRow(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        let isDate: Bool = {
            if case .dateList = form.kind(of: field) { return true }
            return false
        }()

        return Menu {
            choiceMenuItems(section, field)
        } label: {
            HStack(spacing: Spacing.small) {
                Image(systemName: isDate ? Layout.dateIcon : Layout.departureIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: Layout.rowIconSize, height: Layout.rowIconSize)
                    .foregroundStyle(AlmatarColors.iconPrimaryStatic)
                    .accessibilityHidden(true)

                Text(form.selectionRowTitle(section, field))
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isDate {
                    chevron(Layout.forwardChevron)
                }
            }
            .padding(Spacing.medium)
            .modifier(VisitorCardStyle(borderWidth: Layout.borderWidth))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func choiceMenuItems(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        let current = form.value(section, field)
        switch form.kind(of: field) {
        case .dropdown(let options), .segmented(let options):
            ForEach(options) { option in
                Button {
                    form.setValue(option.code, section, field)
                } label: {
                    menuItemLabel(optionTitle(option), isSelected: option.code == current)
                }
            }
        case .dateList(let dates):
            ForEach(dates) { option in
                Button {
                    form.setValue(option.date, section, field)
                } label: {
                    menuItemLabel(form.dateOptionTitle(option), isSelected: option.date == current)
                }
            }
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func menuItemLabel(_ title: String, isSelected: Bool) -> some View {
        if isSelected {
            Label(title, systemImage: "checkmark")
        } else {
            Text(title)
        }
    }

    private func optionTitle(_ option: DynamicFormOption) -> String {
        guard let flag = VisitorDetailsFormModel.flag(for: option.code) else { return option.name }
        return "\(flag) \(option.name)"
    }

    // MARK: - Expandable card

    private func sectionCard(_ section: DynamicFormSection) -> some View {
        let isExpanded = !collapsedSections.contains(section.id)
        let isTravellers = form.isTravellersSection(section)

        return VStack(alignment: .leading, spacing: Spacing.medium) {
            Button {
                withAnimation(.easeInOut) { toggle(section) }
            } label: {
                HStack(spacing: Spacing.small) {
                    Image(systemName: Layout.groupIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: Layout.rowIconSize, height: Layout.rowIconSize)
                        .foregroundStyle(AlmatarColors.iconPrimaryStatic)
                        .accessibilityHidden(true)
                    Text(form.cardTitle(for: section))
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                        .foregroundStyle(AlmatarColors.textPrimaryStatic)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    chevron(isExpanded ? Layout.upChevron : Layout.downChevron)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                if isTravellers {
                    travellerCounters
                    Text(leadGuestTitle)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                        .foregroundStyle(AlmatarColors.textPrimaryStatic)
                }

                VStack(alignment: .leading, spacing: Spacing.medium) {
                    ForEach(Array(form.rows(for: section).enumerated()), id: \.offset) { _, row in
                        HStack(alignment: .top, spacing: Spacing.small) {
                            ForEach(row) { field in
                                fieldView(field, in: section)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
        .padding(Spacing.medium)
        .modifier(VisitorCardStyle(borderWidth: Layout.borderWidth))
    }

    private func toggle(_ section: DynamicFormSection) {
        if collapsedSections.contains(section.id) {
            collapsedSections.remove(section.id)
        } else {
            collapsedSections.insert(section.id)
        }
    }

    // MARK: - Travellers

    private var travellerCounters: some View {
        HStack(spacing: Spacing.small) {
            ForEach(VisitorDetailsFormModel.Traveller.allCases) { traveller in
                counterBox(traveller)
            }
        }
    }

    private func counterBox(_ traveller: VisitorDetailsFormModel.Traveller) -> some View {
        VStack(spacing: Spacing.xSmall) {
            Text(traveller.title)
                .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            HStack(spacing: Spacing.xxSmall) {
                counterButton(
                    icon: Layout.minusIcon,
                    isEnabled: form.canDecrement(traveller),
                    isPrimary: false
                ) { form.decrement(traveller) }

                Text("\(form.count(traveller))")
                    .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .frame(minWidth: Layout.counterValueWidth)

                counterButton(
                    icon: Layout.plusIcon,
                    isEnabled: form.canIncrement(traveller),
                    isPrimary: true
                ) { form.increment(traveller) }
            }

            Text(traveller.ageHint)
                .modifier(AppTextModifier(size: Typography.Size.xSmall, fontWeight: Typography.Weight.regular))
                .foregroundStyle(AlmatarColors.textSecondaryStatic)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, Spacing.small)
        .padding(.horizontal, Spacing.xxSmall)
        .frame(maxWidth: .infinity)
        .overlay(
            RoundedRectangle(cornerRadius: CornerRadius.large)
                .stroke(AlmatarColors.borderDefaultCard, lineWidth: Layout.borderWidth)
        )
        .accessibilityElement(children: .contain)
    }

    private func counterButton(icon: String, isEnabled: Bool, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: Layout.counterIconSize, weight: .semibold))
                .foregroundStyle(isPrimary ? AlmatarColors.textPrimaryInteractive : AlmatarColors.textPrimaryStatic)
                .frame(width: Layout.counterButtonSize, height: Layout.counterButtonSize)
                .background(isPrimary ? AlmatarColors.surfaceSecondaryBase : AlmatarColors.surfaceCardSecondary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : Layout.disabledOpacity)
    }

    // MARK: - Fields

    private func fieldView(_ field: DynamicFormField, in section: DynamicFormSection) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            // Pills need no label, e.g. Mr / Ms / Mrs.
            if !isSegmented(field) {
                Text(field.label)
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }
            control(field, in: section)
        }
    }

    private func isSegmented(_ field: DynamicFormField) -> Bool {
        if case .segmented = form.kind(of: field) { return true }
        return false
    }

    @ViewBuilder
    private func control(_ field: DynamicFormField, in section: DynamicFormSection) -> some View {
        switch form.kind(of: field) {
        case .segmented(let options):
            segmentedControl(options, section, field)
        case .dropdown, .dateList:
            dropdown(section, field)
        case .date:
            dateField(section, field)
        case .phone:
            phoneField(section, field)
        case .email:
            textField(section, field, keyboard: .emailAddress, contentType: .emailAddress)
        case .text:
            textField(section, field, keyboard: .default, contentType: contentType(for: field))
        }
    }

    private func segmentedControl(_ options: [DynamicFormOption], _ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        let current = form.value(section, field)
        return HStack(spacing: Spacing.small) {
            ForEach(options) { option in
                let isSelected = option.code == current
                Button {
                    form.setValue(option.code, section, field)
                } label: {
                    Text(option.name)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(isSelected ? Layout.selectedPillText : AlmatarColors.textPrimaryStatic)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, minHeight: Layout.pillHeight)
                        .background(isSelected ? AlmatarColors.textPrimaryInteractive : Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : AlmatarColors.textSecondaryStatic, lineWidth: Layout.borderWidth)
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    private func dropdown(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        let current = form.value(section, field)
        let flag = VisitorDetailsFormModel.flag(for: current)
        return Menu {
            choiceMenuItems(section, field)
        } label: {
            HStack(spacing: Spacing.small) {
                if let flag, form.selectedText(section, field) != nil {
                    Text(flag)
                }
                inputText(form.selectedText(section, field))
                chevron(Layout.downChevron)
            }
            .modifier(InputBoxStyle(height: Layout.inputHeight))
        }
        .buttonStyle(.plain)
    }

    private func dateField(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        Button {
            pickerDate = form.date(section, field)
                ?? Calendar.current.date(byAdding: .year, value: Layout.defaultBirthYearsAgo, to: Date())
                ?? Date()
            dateTarget = DateTarget(section: section, field: field)
        } label: {
            HStack(spacing: Spacing.small) {
                inputText(form.selectedText(section, field))
                chevron(Layout.downChevron)
            }
            .modifier(InputBoxStyle(height: Layout.inputHeight))
        }
        .buttonStyle(.plain)
    }

    private func datePickerSheet(_ target: DateTarget) -> some View {
        VStack(spacing: Spacing.zero) {
            HStack {
                Spacer()
                Button(doneTitle) {
                    form.setDate(pickerDate, target.section, target.field)
                    dateTarget = nil
                }
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryInteractive)
            }
            .padding(Spacing.medium)

            DatePicker("", selection: $pickerDate, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .environment(\.locale, Locale(identifier: AlmatarStaticPackageSDK.shared.configuration.language.rawValue))
        }
        .presentationDetents([.height(Layout.datePickerHeight)])
    }

    private func phoneField(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        let country = form.phoneCountry(section, field)
        return HStack(spacing: Spacing.small) {
            Menu {
                ForEach(VisitorDetailsFormModel.phoneCountries) { option in
                    Button {
                        form.setPhoneCountry(option, section, field)
                    } label: {
                        menuItemLabel(
                            [VisitorDetailsFormModel.flag(for: option.code), option.dialCode].compactMap { $0 }.joined(separator: " "),
                            isSelected: option == country
                        )
                    }
                }
            } label: {
                HStack(spacing: Spacing.xSmall) {
                    if let flag = VisitorDetailsFormModel.flag(for: country.code) {
                        Text(flag)
                    }
                    Text(country.dialCode)
                        .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(AlmatarColors.textPrimaryStatic)
                        .lineLimit(1)
                    chevron(Layout.downChevron)
                }
                .fixedSize()
                .modifier(InputBoxStyle(height: Layout.inputHeight))
            }
            .buttonStyle(.plain)
            .environment(\.layoutDirection, .leftToRight)

            textField(section, field, keyboard: .phonePad, contentType: .telephoneNumber)
        }
    }

    private func textField(
        _ section: DynamicFormSection,
        _ field: DynamicFormField,
        keyboard: UIKeyboardType,
        contentType: UITextContentType?
    ) -> some View {
        TextField(
            "",
            text: Binding(
                get: { form.value(section, field) },
                set: { form.setValue($0, section, field) }
            )
        )
        .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
        .foregroundStyle(AlmatarColors.textPrimaryStatic)
        .keyboardType(keyboard)
        .textContentType(contentType)
        .textInputAutocapitalization(keyboard == .default ? .words : .never)
        .autocorrectionDisabled()
        .modifier(InputBoxStyle(height: Layout.inputHeight))
        .accessibilityLabel(field.label)
    }

    private func contentType(for field: DynamicFormField) -> UITextContentType? {
        switch field.field {
        case "firstName": return .givenName
        case "lastName": return .familyName
        default: return nil
        }
    }

    // MARK: - Helpers

    /// Selected value, or a muted "Select" placeholder.
    private func inputText(_ text: String?) -> some View {
        Text(text ?? selectTitle)
            .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
            .foregroundStyle(text == nil ? AlmatarColors.textSecondaryStatic : AlmatarColors.textPrimaryStatic)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func chevron(_ name: String) -> some View {
        Image(systemName: name)
            .font(.system(size: Layout.chevronSize, weight: .semibold))
            .foregroundStyle(AlmatarColors.iconPrimaryStatic)
            .accessibilityHidden(true)
    }
}

// MARK: - Styles

/// White rounded card with a hairline border.
private struct VisitorCardStyle: ViewModifier {
    let borderWidth: CGFloat

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AlmatarColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.xLarge))
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.xLarge)
                    .stroke(AlmatarColors.borderDefaultCard, lineWidth: borderWidth)
            )
    }
}

/// Filled input box used by text fields, dropdowns and the date field.
private struct InputBoxStyle: ViewModifier {
    let height: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, Spacing.medium)
            .frame(minHeight: height)
            .background(AlmatarColors.surfaceCardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.medium))
    }
}

// MARK: - Traveller strings

private extension VisitorDetailsFormModel.Traveller {
    @MainActor
    var title: String {
        switch self {
        case .adults: return LocalizedKey.adults.localized()
        case .children: return LocalizedKey.children.localized()
        case .infants: return LocalizedKey.infants.localized()
        }
    }

    @MainActor
    var ageHint: String {
        switch self {
        case .adults: return LocalizedKey.adultsAgeHint.localized()
        case .children: return LocalizedKey.childrenAgeHint.localized()
        case .infants: return LocalizedKey.infantsAgeHint.localized()
        }
    }
}
