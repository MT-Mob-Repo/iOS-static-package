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
        static let flagSize: CGFloat = 24
        static let counterButtonSize: CGFloat = 28
        static let counterIconSize: CGFloat = 12
        static let counterValueWidth: CGFloat = 24
        static let nationalityChevronSize: CGFloat = 14
        static let countryPickerHeightFraction: CGFloat = 0.98
        static let counterStrokeWidth: CGFloat = 2
        /// The minus line's width at its narrowest, as a fraction of its full width.
        static let minusCollapsedScale: CGFloat = 0.15
        static let datePickerHeight: CGFloat = 340
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
    }

    /// The picker section whose selection sheet is open.
    private struct SelectionTarget: Identifiable {
        let section: DynamicFormSection
        let field: DynamicFormField
        var id: String { "\(section.section.rawValue).\(field.field)" }
    }

    /// The nationality field whose country picker is open.
    private struct NationalityTarget: Identifiable {
        let section: DynamicFormSection
        let field: DynamicFormField
        var id: String { "\(section.section.rawValue).\(field.field)" }
    }

    /// The free-date field whose picker sheet is open.
    private struct DateTarget: Identifiable {
        let section: DynamicFormSection
        let field: DynamicFormField
        var id: String { "\(section.section.rawValue).\(field.field)" }
    }

    @ObservedObject var form: VisitorDetailsFormModel
    /// `true` while the cart is being updated or payment is starting; the counters are locked meanwhile.
    var isLoading = false

    /// Expandable cards start open.
    @State private var collapsedSections: Set<String> = []
    @State private var dateTarget: DateTarget?
    @State private var selectionTarget: SelectionTarget?
    @State private var nationalityTarget: NationalityTarget?
    @State private var pickerDate = Date()
    /// The visitor whose removal is waiting for confirmation.
    @State private var visitorToRemove: VisitorDetailsFormModel.Visitor?
    /// "<name> removed." after a visitor is removed.
    @State private var toastMessage: ToastMessage?
    /// The counter button animating until the cart allocation it caused finishes.
    @State private var counterAnimation: CounterAnimationTarget?
    /// Identifies the current run, so a stopped run's pending steps don't continue a newer one.
    @State private var counterAnimationId = UUID()
    /// How much of the stroke around the animating plus is drawn (0...1).
    @State private var plusStrokeProgress: CGFloat = .zero
    /// Whether the animating minus line is currently collapsed.
    @State private var isMinusCollapsed = false
    /// Whether loading started since the animation did; the animation stops when that loading ends.
    @State private var hasSeenLoading = false

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
                ForEach(orderedSections) { section in
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

    // MARK: - Ordering

    /// Departure city, then departure date, then passenger, then any unknown sections in backend order.
    private var orderedSections: [DynamicFormSection] {
        form.sections.enumerated()
            .sorted { lhs, rhs in
                let lhsOrder = lhs.element.section.sortOrder
                let rhsOrder = rhs.element.section.sortOrder
                return lhsOrder == rhsOrder ? lhs.offset < rhs.offset : lhsOrder < rhsOrder
            }
            .map(\.element)
    }

    // MARK: - Selection row

    /// Collapsed row that opens a bottom sheet with the field's choices, e.g. "Departure Riyadh".
    private func selectionRow(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        let isDate: Bool = {
            switch form.kind(of: field) {
            case .dateList, .date: return true
            default: return false
            }
        }()
        let isSelectable = form.isSelectable(section)

        return Button {
            guard isSelectable else { return }
            if case .date = form.kind(of: field) {
                openDatePicker(section, field)
            } else {
                selectionTarget = SelectionTarget(section: section, field: field)
            }
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

                if isSelectable {
                    chevron(isDate ? Layout.forwardChevron : Layout.downChevron)
                }
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

    private func optionTitle(_ option: DynamicFormOption) -> String {
        let name = form.optionName(option)
        guard let flag = VisitorDetailsFormModel.flag(for: option.code) else { return name }
        return "\(flag) \(name)"
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
        .toast(item: $toastMessage)
        .popup(item: $visitorToRemove) { visitor in
            removeVisitorPopup(visitor)
        }
        .onChange(of: isLoading) { loading in
            if loading {
                hasSeenLoading = true
            } else {
                // The allocation finished, successfully or not.
                stopCounterAnimation()
            }
        }
    }

    /// One field per row; first and last name share a row, as in the Almatar app forms.
    private func fieldsList(_ section: DynamicFormSection) -> some View {
        VStack(alignment: .leading, spacing: Spacing.medium) {
            ForEach(Array(form.rows(for: section).enumerated()), id: \.offset) { _, row in
                HStack(alignment: .top, spacing: Spacing.medium) {
                    ForEach(row) { field in
                        fieldView(field, in: section)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
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
            message: LocalizedKey.removeVisitorMessage.localized(with: form.nameOrNumberTitle(visitor)),
            cancelTitle: cancelTitle,
            confirmTitle: removeTitle,
            isDestructive: true,
            onConfirm: {
                // Read before the visitor and their details are removed.
                let name = form.nameOrNumberTitle(visitor)
                withAnimation(.easeInOut) { form.remove(visitor) }
                // Animate this type's minus until the cart is updated.
                startCounterAnimation(CounterAnimationTarget(traveller: visitor.type, button: .minus))
                toastMessage = ToastMessage(text: LocalizedKey.visitorRemoved.localized(with: name))
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
                let minus = CounterAnimationTarget(traveller: traveller, button: .minus)
                counterButton(
                    icon: Layout.minusIcon,
                    isEnabled: form.canDecrement(traveller),
                    isPrimary: false,
                    iconWidthScale: counterAnimation == minus && isMinusCollapsed ? Layout.minusCollapsedScale : 1
                ) {
                    guard form.canDecrement(traveller), !isCounterLocked else { return }
                    visitorToRemove = form.lastRemovableVisitor(of: traveller)
                }

                Text("\(form.count(traveller))")
                    .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.semibold))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .frame(minWidth: Layout.counterValueWidth)

                let plus = CounterAnimationTarget(traveller: traveller, button: .plus)
                counterButton(
                    icon: Layout.plusIcon,
                    isEnabled: form.canIncrement(traveller),
                    isPrimary: true,
                    strokeProgress: counterAnimation == plus ? plusStrokeProgress : nil
                ) {
                    guard form.canIncrement(traveller), !isCounterLocked else { return }
                    form.increment(traveller)
                    startCounterAnimation(plus)
                }
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

    /// Plus is purple and minus neutral; both turn grey when disabled,
    /// e.g. every plus once the group reaches the package's visitor limit.
    /// While loading, every counter button is disabled and grey, except the one animating.
    ///
    /// - `isAnimating`: the button whose change is being allocated; it keeps its colors while loading.
    /// - `strokeProgress`: how much of the animated stroke around the button is drawn; `nil` hides it.
    /// - `iconWidthScale`: squeezes the icon horizontally, for the minus collapse animation.
    private func counterButton(
        icon: String,
        isEnabled: Bool,
        isPrimary: Bool,
        strokeProgress: CGFloat? = nil,
        iconWidthScale: CGFloat = 1,
        action: @escaping () -> Void
    ) -> some View {
        let foreground: Color = {
            guard isEnabled else { return AlmatarColors.iconDisabled }
            return isPrimary ? AlmatarColors.textPrimaryInteractive : AlmatarColors.textPrimaryStatic
        }()
        let background = isEnabled && isPrimary ? AlmatarColors.surfaceSecondaryBase : AlmatarColors.surfaceCardSecondary

        return Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: Layout.counterIconSize, weight: .semibold))
                .foregroundStyle(foreground)
                .scaleEffect(x: iconWidthScale, y: 1)
                .frame(width: Layout.counterButtonSize, height: Layout.counterButtonSize)
                .background(background)
                .clipShape(Circle())
                .overlay {
                    if let strokeProgress {
                        Circle()
                            .inset(by: Layout.counterStrokeWidth / 2)
                            .trim(from: .zero, to: strokeProgress)
                            .stroke(AlmatarColors.textPrimaryInteractive, lineWidth: Layout.counterStrokeWidth)
                            // Start drawing from the top.
                            .rotationEffect(.degrees(-90))
                            .transition(.opacity)
                    }
                }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Counter animations

    /// Counter taps are ignored while loading or while a change is still being allocated.
    private var isCounterLocked: Bool {
        isLoading || counterAnimation != nil
    }

    private enum CounterAnimation {
        /// One sweep of the stroke around the plus.
        static let strokeDuration: Double = 0.6
        /// Pause between sweeps.
        static let strokePause: Double = 0.15
        static let fadeDuration: Double = 0.2
        /// One half of the minus pulse: collapsing or expanding.
        static let minusPulseDuration: Double = 0.3
        /// The allocation starts after the visitors form's sync delay; stop if no loading starts by then.
        static let loadingStartTimeout: Double = 1.5
    }

    /// Animates `target` until the cart allocation finishes.
    private func startCounterAnimation(_ target: CounterAnimationTarget) {
        let runId = UUID()
        counterAnimationId = runId
        counterAnimation = target
        hasSeenLoading = isLoading
        switch target.button {
        case .plus:
            plusStrokeProgress = .zero
            sweepPlusStroke(runId)
        case .minus:
            isMinusCollapsed = false
            pulseMinus(runId)
        }
        // e.g. the change was undone before syncing, so there is nothing to allocate.
        DispatchQueue.main.asyncAfter(deadline: .now() + CounterAnimation.loadingStartTimeout) {
            guard isRunning(runId), !hasSeenLoading, !isLoading else { return }
            stopCounterAnimation()
        }
    }

    private func stopCounterAnimation() {
        guard counterAnimation != nil else { return }
        withAnimation(.easeOut(duration: CounterAnimation.fadeDuration)) {
            counterAnimation = nil
            isMinusCollapsed = false
        }
        plusStrokeProgress = .zero
        hasSeenLoading = false
    }

    private func isRunning(_ runId: UUID) -> Bool {
        counterAnimation != nil && counterAnimationId == runId
    }

    /// Draws the stroke around the plus from the top, then starts again while still animating.
    private func sweepPlusStroke(_ runId: UUID) {
        guard isRunning(runId) else { return }
        plusStrokeProgress = .zero
        // Animate on the next run loop so SwiftUI sees the reset first.
        DispatchQueue.main.async {
            guard isRunning(runId) else { return }
            withAnimation(.easeInOut(duration: CounterAnimation.strokeDuration)) {
                plusStrokeProgress = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + CounterAnimation.strokeDuration + CounterAnimation.strokePause) {
            sweepPlusStroke(runId)
        }
    }

    /// Collapses and expands the minus line in turn while still animating.
    private func pulseMinus(_ runId: UUID) {
        guard isRunning(runId) else { return }
        withAnimation(.easeInOut(duration: CounterAnimation.minusPulseDuration)) {
            isMinusCollapsed.toggle()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + CounterAnimation.minusPulseDuration) {
            pulseMinus(runId)
        }
    }

    // MARK: - Fields

    /// Label above the control, as in the Almatar app forms.
    /// The nationality button shows its own title, so it gets no extra label.
    @ViewBuilder
    private func fieldView(_ field: DynamicFormField, in section: DynamicFormSection) -> some View {
        if form.kind(of: field) == .nationality {
            nationalityField(section, field)
        } else {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(field.label)
                    .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                    .foregroundStyle(AlmatarColors.textPrimaryStatic)
                    .frame(maxWidth: .infinity, alignment: .leading)

                control(field, in: section)
            }
        }
    }

    @ViewBuilder
    private func control(_ field: DynamicFormField, in section: DynamicFormSection) -> some View {
        switch form.kind(of: field) {
        case .segmented(let options):
            pills(options, section, field)
        case .dropdown, .dateList:
            dropdownButton(section, field)
        case .date:
            dateButton(section, field)
        case .phone:
            phoneField(section, field)
        case .nationality:
            nationalityField(section, field)
        case .email:
            textField(section, field, keyboard: .emailAddress)
        case .number:
            textField(section, field, keyboard: .numberPad)
        case .text:
            textField(section, field, keyboard: .default)
        }
    }

    /// Text input from the design system, validated with the field's rule once it loses focus.
    private func textField(_ section: DynamicFormSection, _ field: DynamicFormField, keyboard: UIKeyboardType) -> some View {
        SUITextField(
            text: Binding(
                get: { form.value(section, field) },
                set: { form.setValue($0, section, field) }
            ),
            placeholder: LocalizedKey.enterFieldPlaceholder.localized(with: field.label),
            validator: form.validatorType(for: field, in: section),
            keyboardType: keyboard,
            background: AlmatarColors.surfaceCardSecondary,
            shouldValidateAfterFocused: true,
            shouldValidate: $form.shouldValidate
        )
    }

    /// Phone input from the design system, with its own country code list.
    private func phoneField(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        SUIPhoneView(
            placeholder: LocalizedKey.enterFieldPlaceholder.localized(with: field.label),
            phoneNumber: Binding(
                get: { form.value(section, field) },
                set: { form.setValue($0.filter(\.isNumber), section, field) }
            ),
            phoneNumberCode: Binding(
                get: { form.phoneCode(section, field) },
                set: { form.setPhoneCode($0, section, field) }
            ),
            phoneCountryName: Binding(
                get: { form.phoneCountryName(section, field) },
                set: { form.setPhoneCountryName($0, section, field) }
            ),
            background: AlmatarColors.surfaceCardSecondary,
            shouldValidate: $form.shouldValidate,
            isTextFieldFocused: false
        )
    }

    /// Nationality button from the design system with the country's flag;
    /// tapping it opens the design system's country picker.
    private func nationalityField(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        let target = NationalityTarget(section: section, field: field)
        return SUINationalityTextAndImageButton(
            title: field.label,
            placeholder: field.label,
            text: Binding(
                get: { form.nationalityName(section, field) },
                set: { _ in }
            ),
            validator: form.nationalityValidator(for: field),
            background: AlmatarColors.surfaceCardSecondary,
            shouldValidate: $form.shouldValidate,
            contentImageView: {
                Image(systemName: Layout.downChevron)
                    .font(.system(size: Layout.nationalityChevronSize))
                    .foregroundStyle(AlmatarColors.textSecondaryStatic)
            },
            leadingImageView: form.nationalityCountry(section, field)?.flag ?? UIImage()
        )
        .contentShape(Rectangle())
        .onTapGesture {
            nationalityTarget = target
        }
        .sheet(isPresented: Binding(
            get: { nationalityTarget?.id == target.id },
            set: { if !$0 { nationalityTarget = nil } }
        )) {
            CountryPickerView(viewModel: CountryPickerViewModel(
                AlmatarStaticPackageSDK.shared.configuration.language == .arabic ? .arabic : .english,
                didSelectCountry: { country in
                    form.setNationality(country, section, field)
                    nationalityTarget = nil
                }
            ))
            .presentationDetents([.fraction(Layout.countryPickerHeightFraction)])
        }
    }

    /// Short choices as pills, e.g. Male / Female or Mr / Ms / Mrs.
    private func pills(_ options: [DynamicFormOption], _ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        let current = form.value(section, field)
        return HStack(spacing: Spacing.medium) {
            ForEach(options) { option in
                let isSelected = option.code == current
                Button {
                    form.setValue(option.code, section, field)
                } label: {
                    Text(form.optionName(option))
                        .modifier(AppTextModifier(size: Typography.Size.regular, fontWeight: Typography.Weight.regular))
                        .foregroundStyle(isSelected ? AlmatarColors.textPrimaryInteractive : AlmatarColors.textPrimaryStatic)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.small)
                        .background(isSelected ? AlmatarColors.surfaceSecondaryBase : Color.clear)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(
                                isSelected ? AlmatarColors.borderPrimary : AlmatarColors.borderDefaultCard,
                                lineWidth: Layout.borderWidth
                            )
                        )
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    /// Opens the list of choices in a bottom sheet, e.g. nationality.
    private func dropdownButton(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        let selected = form.selectedText(section, field)
        let flag = selected == nil ? nil : VisitorDetailsFormModel.flag(for: form.value(section, field))
        return Button {
            selectionTarget = SelectionTarget(section: section, field: field)
        } label: {
            HStack(spacing: Spacing.xSmall) {
                if let flag {
                    Text(flag)
                        .frame(width: Layout.flagSize, height: Layout.flagSize)
                }
                fieldText(selected, placeholder: LocalizedKey.selectFieldPlaceholder.localized(with: field.label))
                chevron(Layout.downChevron)
            }
            .dropdownFieldStyle()
        }
        .buttonStyle(.plain)
    }

    private func dateButton(_ section: DynamicFormSection, _ field: DynamicFormField) -> some View {
        Button {
            openDatePicker(section, field)
        } label: {
            HStack(spacing: Spacing.xSmall) {
                fieldText(form.selectedText(section, field), placeholder: dateOfBirthPlaceholder)
                chevron(Layout.downChevron)
            }
            .dropdownFieldStyle()
        }
        .buttonStyle(.plain)
    }

    private func openDatePicker(_ section: DynamicFormSection, _ field: DynamicFormField) {
        let range = form.dateRange(for: field)
        pickerDate = form.date(section, field) ?? range.upperBound
        dateTarget = DateTarget(section: section, field: field)
    }

    /// Wheel picker limited to the field's dates, with a "Done" button, as in the Almatar app forms.
    private func datePickerSheet(_ target: DateTarget) -> some View {
        VStack(spacing: Spacing.medium) {
            DatePicker(
                "",
                selection: $pickerDate,
                in: form.dateRange(for: target.field),
                displayedComponents: .date
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .environment(\.locale, Locale(identifier: AlmatarStaticPackageSDK.shared.configuration.language.rawValue))

            PrimaryButton(doneTitle, addPadding: false) {
                form.setDate(pickerDate, target.section, target.field)
                dateTarget = nil
            }
            .padding(.horizontal, Spacing.large)
        }
        .padding(.top, Spacing.large)
        .presentationDetents([.height(Layout.datePickerHeight)])
    }

    // MARK: - Helpers

    /// Selected value, or a muted placeholder.
    private func fieldText(_ text: String?, placeholder: String) -> some View {
        Text(text ?? placeholder)
            .modifier(AppTextModifier(size: Typography.Size.medium, fontWeight: Typography.Weight.regular))
            .foregroundStyle(text == nil ? AlmatarColors.borderTertiaryDisabled : AlmatarColors.textPrimaryStatic)
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

private extension View {
    /// Filled box of dropdown and date fields, matching the design-system text fields.
    func dropdownFieldStyle() -> some View {
        self
            .frame(maxWidth: .infinity)
            .padding(Spacing.medium)
            .background(AlmatarColors.surfaceCardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: CornerRadius.large))
            .contentShape(Rectangle())
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

// MARK: - Counter animation target

/// A counter button animating while its change is allocated, e.g. the adults' plus.
private struct CounterAnimationTarget: Equatable {
    enum Button {
        case plus, minus
    }

    let traveller: VisitorDetailsFormModel.Traveller
    let button: Button
}
