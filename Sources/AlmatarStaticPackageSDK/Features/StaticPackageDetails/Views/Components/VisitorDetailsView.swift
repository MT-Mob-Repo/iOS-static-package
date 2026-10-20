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
        static let checkmarkIcon = "checkmark"
        static let visitorIcon = "person"
        static let removeIcon = "trash"
        static let avatarSize: CGFloat = 40
        static let avatarIconSize: CGFloat = 18
        static let illustrationSize: CGFloat = 96
        // TODO: Replace with the design-system "on primary" text color once available.
        static let selectedPillText = Color.white
    }

    /// The picker section whose selection sheet is open.
    private struct SelectionTarget: Identifiable {
        let section: DynamicFormSection
        let field: DynamicFormField
        var id: String { "\(section.section).\(field.field)" }
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
    @State private var selectionTarget: SelectionTarget?
    @State private var pickerDate = Date()
    /// The visitor whose removal is waiting for confirmation.
    @State private var visitorToRemove: VisitorDetailsFormModel.Visitor?

    private let selectTitle = LocalizedKey.select.localized()
    private let completedTitle = LocalizedKey.completed.localized()
    private let incompleteTitle = LocalizedKey.incomplete.localized()
    private let removeVisitorTitle = LocalizedKey.removeVisitor.localized()
    private let removeTitle = LocalizedKey.remove.localized()
    private let cancelTitle = LocalizedKey.cancel.localized()
    private let dateOfBirthPlaceholder = LocalizedKey.dateOfBirthPlaceholder.localized()
    private let doneTitle = LocalizedKey.done.localized()
    private let confirmDatesTitle = LocalizedKey.confirmDates.localized()
    private let returnDateTitle = LocalizedKey.returnDateAutoSet.localized()

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
            // Attached here, not next to the date picker sheet, so both sheets present reliably on iOS 16.
            .sheet(item: $selectionTarget) { target in
                selectionSheet(target)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(item: $dateTarget) { target in
            datePickerSheet(target)
        }
    }

    // MARK: - Selection row

    /// Collapsed row that opens a bottom sheet with the field's choices, e.g. "Departure Riyadh".
    private func selectionRow(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        let isDate = form.isDateList(field)

        return Button {
            selectionTarget = SelectionTarget(section: section, field: field)
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

                chevron(isDate ? Layout.forwardChevron : Layout.downChevron)
            }
            .padding(Spacing.medium)
            .modifier(VisitorCardStyle(borderWidth: Layout.borderWidth))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Selection sheet

    @ViewBuilder
    private func selectionSheet(_ target: SelectionTarget) -> some View {
        let title = form.selectionSheetTitle(target.field)
        switch form.kind(of: target.field) {
        case .dateList(let options):
            SelectionBottomSheet(
                title: title,
                sections: form.dateSheetSections(options),
                selected: form.selectedDateOption(target.section, target.field),
                confirmTitle: confirmDatesTitle,
                onSelect: { form.setValue($0.date, target.section, target.field) }
            ) { option, _ in
                dateOptionRow(option)
            }
        case .dropdown(let options), .segmented(let options):
            SelectionBottomSheet(
                title: title,
                sections: form.optionSheetSections(options),
                selected: form.selectedOption(target.section, target.field),
                onSelect: { form.setValue($0.code, target.section, target.field) }
            ) { option, isSelected in
                optionRow(option, isSelected: isSelected)
            }
        default:
            EmptyView()
        }
    }

    /// "Sunday, 19 July" and "Return date automatically set: 21 July 2026".
    private func dateOptionRow(_ option: DynamicFormDateOption) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xSmall) {
            Text(form.dateOptionDayTitle(option))
                .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)

            if let returnDate = form.returnDateText(option) {
                HStack(spacing: Spacing.xxSmall) {
                    Text(returnDateTitle)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    Text(returnDate)
                        .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.semibold))
                }
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
            }
        }
    }

    /// Flag (when the code is a country) and name, with a checkmark when selected.
    private func optionRow(_ option: DynamicFormOption, isSelected: Bool) -> some View {
        HStack(spacing: Spacing.small) {
            Text(optionTitle(option))
                .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.medium))
                .foregroundStyle(AlmatarColors.textPrimaryStatic)
                .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: Layout.checkmarkIcon)
                    .font(.system(size: Layout.chevronSize, weight: .semibold))
                    .foregroundStyle(AlmatarColors.iconPrimaryInteractive)
                    .accessibilityHidden(true)
            }
        }
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

    /// Collapsible card. The travellers section shows the counters and one card per visitor;
    /// any other section shows its fields.
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
                        .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
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
                    VStack(spacing: Spacing.small) {
                        ForEach(form.visitors) { visitorCard($0) }
                    }
                } else {
                    fieldsList(section)
                }
            }
        }
        .padding(Spacing.medium)
        .modifier(VisitorCardStyle(borderWidth: Layout.borderWidth))
        .popup(item: $visitorToRemove) { visitor in
            removeVisitorPopup(visitor)
        }
    }

    private func fieldsList(_ section: DynamicFormSection) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            ForEach(section.fields) { field in
                fieldView(field, in: section)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    // MARK: - Visitor card

    private func visitorCard(_ visitor: VisitorDetailsFormModel.Visitor) -> some View {
        let isExpanded = form.isExpanded(visitor)

        return VStack(alignment: .leading, spacing: Spacing.medium) {
            Button {
                withAnimation(.easeInOut) { form.toggleExpanded(visitor) }
            } label: {
                visitorHeader(visitor, isExpanded: isExpanded)
            }
            .buttonStyle(.plain)

            if isExpanded, let section = form.section(for: visitor) {
                fieldsList(section)

                if form.canRemove(visitor) {
                    removeVisitorButton(visitor)
                }
            }
        }
        .padding(Spacing.medium)
        .modifier(VisitorCardStyle(borderWidth: Layout.borderWidth))
    }

    private func visitorHeader(_ visitor: VisitorDetailsFormModel.Visitor, isExpanded: Bool) -> some View {
        HStack(spacing: Spacing.small) {
            Image(systemName: Layout.visitorIcon)
                .font(.system(size: Layout.avatarIconSize, weight: .medium))
                .foregroundStyle(AlmatarColors.iconPrimaryInteractive)
                .frame(width: Layout.avatarSize, height: Layout.avatarSize)
                .background(AlmatarColors.surfaceSecondaryBase)
                .clipShape(Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxxSmall) {
                Text(form.displayName(visitor))
                    .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .lineLimit(1)
                Text(form.roleTitle(visitor))
                    .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            statusPill(isComplete: form.isComplete(visitor))

            chevron(isExpanded ? Layout.upChevron : Layout.downChevron)
        }
        .contentShape(Rectangle())
    }

    private func statusPill(isComplete: Bool) -> some View {
        Text(isComplete ? completedTitle : incompleteTitle)
            .modifier(AppTextModifier(size: Typography.Size.small, fontWeight: Typography.Weight.regular))
            .foregroundStyle(isComplete ? AlmatarColors.textComplementaryGreen : AlmatarColors.textSecondaryStatic)
            .lineLimit(1)
            .padding(.horizontal, Spacing.small)
            .padding(.vertical, Spacing.xxSmall)
            .background(isComplete ? AlmatarColors.surfaceComplementaryGreen : AlmatarColors.surfaceCardSecondary)
            .clipShape(Capsule())
    }

    private func removeVisitorButton(_ visitor: VisitorDetailsFormModel.Visitor) -> some View {
        Button {
            visitorToRemove = visitor
        } label: {
            HStack(spacing: Spacing.xSmall) {
                Image(systemName: Layout.removeIcon)
                    .font(.system(size: Layout.rowIconSize, weight: .regular))
                Text(removeVisitorTitle)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.semibold))
            }
            .foregroundStyle(AlmatarColors.textComplementaryRed)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func removeVisitorPopup(_ visitor: VisitorDetailsFormModel.Visitor) -> some View {
        ConfirmationPopup(
            title: LocalizedKey.removeVisitorSheetTitle.localized(),
            message: LocalizedKey.removeVisitorMessage.localized(with: form.visitorNumberTitle(visitor)),
            cancelTitle: cancelTitle,
            confirmTitle: removeTitle,
            isDestructive: true,
            onConfirm: {
                withAnimation(.easeInOut) { form.remove(visitor) }
            }
        ) {
            removeVisitorIllustration
        }
    }

    /// Person with a trash badge. SDK images must load from the SDK bundle (`.module`),
    /// not the host app's main bundle.
    private var removeVisitorIllustration: some View {
        Image(PackageAsset.removeVisitorIcon, bundle: .module)
            .resizable()
            .scaledToFit()
            .frame(width: Layout.illustrationSize, height: Layout.illustrationSize)
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
                ) {
                    // Same confirmation as "Remove visitor", for the last visitor of this type.
                    visitorToRemove = form.lastRemovableVisitor(of: traveller)
                }

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
                inputText(form.selectedText(section, field), placeholder: LocalizedKey.selectFieldPlaceholder.localized(with: field.label))
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
                inputText(form.selectedText(section, field), placeholder: dateOfBirthPlaceholder)
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
            LocalizedKey.enterFieldPlaceholder.localized(with: field.label),
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

    /// Selected value, or a muted placeholder ("Select" by default).
    private func inputText(_ text: String?, placeholder: String? = nil) -> some View {
        Text(text ?? placeholder ?? selectTitle)
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
