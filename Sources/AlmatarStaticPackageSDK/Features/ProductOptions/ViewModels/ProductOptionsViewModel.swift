//
//  ProductOptionsViewModel.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// One choice among a product's options, e.g. the flight cabin class.
@MainActor
final class ProductOptionsViewModel: ObservableObject {
    let section: ProductOptionsSection
    /// The visitors form, for the count the per-visitor prices are multiplied by.
    let visitorForm: VisitorDetailsFormModel
    let breakdownSections: [PriceBreakdownSection]

    @Published private(set) var selectedOption: ProductOption?

    /// Package total without this product's option, in the cart currency.
    private let baseAmount: Double
    private let currency: String?
    private let onConfirm: (ProductOption?) -> Void

    init(
        section: ProductOptionsSection,
        selectedOption: ProductOption?,
        visitorForm: VisitorDetailsFormModel,
        baseAmount: Double,
        currency: String?,
        breakdownSections: [PriceBreakdownSection],
        onConfirm: @escaping (ProductOption?) -> Void
    ) {
        self.section = section
        self.visitorForm = visitorForm
        self.baseAmount = baseAmount
        self.currency = currency
        self.breakdownSections = breakdownSections
        self.onConfirm = onConfirm
        // Keep the previous choice, else start on the included option, as in the design.
        self.selectedOption = selectedOption ?? section.options?.first { Self.isIncluded($0) }
    }

    // MARK: - Strings

    var title: String { section.title.nonEmpty ?? LocalizedKey.selectOptions.localized() }
    var note: String? { section.note.nonEmpty }
    var includedTitle: String { LocalizedKey.itineraryIncluded.localized() }
    var perVisitorTitle: String { LocalizedKey.perVisitor.localized() }
    var continueTitle: String { LocalizedKey.continueTitle.localized() }
    var priceDetailsTitle: String { LocalizedKey.priceDetails.localized() }

    func totalLabel(visitorCount: Int) -> String {
        visitorCount == 1
            ? LocalizedKey.totalPriceOneVisitor.localized()
            : LocalizedKey.totalPriceVisitors.localized(with: visitorCount)
    }

    // MARK: - Options

    var options: [ProductOption] { section.options ?? [] }

    func isSelected(_ option: ProductOption) -> Bool { option == selectedOption }

    func isAvailable(_ option: ProductOption) -> Bool { option.isAvailable ?? true }

    func isIncluded(_ option: ProductOption) -> Bool { Self.isIncluded(option) }

    func select(_ option: ProductOption) {
        guard isAvailable(option) else { return }
        selectedOption = option
    }

    /// e.g. "+840 SAR", converted to the selected currency.
    func priceText(_ option: ProductOption) -> String {
       CurrencyManager.shared.formatPrice(value: option.price ?? 0, currencyCode: option.currency ?? currency)
    }

    // MARK: - Total

    /// The selected option's cost for the whole group.
    func upgradeAmount(visitorCount: Int) -> Double {
        (selectedOption?.price ?? 0) * Double(visitorCount)
    }

    func totalAmountText(visitorCount: Int) -> String? {
        CurrencyManager.shared.formatPrice(value: baseAmount + upgradeAmount(visitorCount: visitorCount), currencyCode: currency)
    }

    /// e.g. "+ 1,680 SAR • Cabin upgrade"; `nil` while the included option is selected.
    func upgradeDetailText(visitorCount: Int) -> String? {
        let amount = upgradeAmount(visitorCount: visitorCount)
        guard amount > 0 else { return nil }
        return "+ \(CurrencyManager.shared.formatPrice(value: amount, currencyCode: currency)) • \(title)"
    }

    // MARK: - Actions

    func continueTapped() {
        onConfirm(selectedOption)
    }

    private static func isIncluded(_ option: ProductOption) -> Bool {
        (option.price ?? 0) == 0
    }
}
