//
//  ProductOptionsViewModel.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// One choice among a product's options, e.g. the flight cabin class.
/// Each new choice is allocated in the cart right away, and the footer shows the re-priced cart.
@MainActor
final class ProductOptionsViewModel: ObservableObject {
    let section: ProductOptionsSection
    /// The visitors form, for the visitor count shown in the footer.
    let visitorForm: VisitorDetailsFormModel

    @Published private(set) var selectedOption: ProductOption?
    /// The cart price after the last allocation; drives the footer total and breakdown.
    @Published private(set) var cartPrice: CartPrice?
    /// Set when a choice could not be allocated; shown as an alert.
    @Published var errorMessage: String?
    /// Number of choices being allocated; see `isUpdatingCart`.
    @Published private var pendingSelections = 0

    /// `true` while the cart is re-priced after a choice.
    var isUpdatingCart: Bool { pendingSelections > 0 }

    /// The option the cart currently holds; the selection returns to it when an allocation fails.
    private var allocatedOption: ProductOption?
    /// Allocates the option in the cart and reloads it; returns the error message, or `nil` on success.
    private let allocateOption: (ProductOption?) async -> String?
    /// The cart price after a reload.
    private let currentCartPrice: () -> CartPrice?

    init(
        section: ProductOptionsSection,
        visitorForm: VisitorDetailsFormModel,
        cartPrice: CartPrice?,
        allocateOption: @escaping (ProductOption?) async -> String?,
        currentCartPrice: @escaping () -> CartPrice?
    ) {
        self.section = section
        self.visitorForm = visitorForm
        self.cartPrice = cartPrice
        self.allocateOption = allocateOption
        self.currentCartPrice = currentCartPrice
        // The option the cart marks as selected, else the product's default one.
        let initial = section.options?.first(where: \.selected)
            ?? section.options?.first(where: \.isDefault)
        self.selectedOption = initial
        self.allocatedOption = initial
    }

    // MARK: - Strings

    var title: String { section.title.nonEmpty ?? LocalizedKey.selectOptions.localized() }
    var note: String? { section.note.nonEmpty }
    var includedTitle: String { LocalizedKey.itineraryIncluded.localized() }
    var perVisitorTitle: String { LocalizedKey.perVisitor.localized() }
    var continueTitle: String { LocalizedKey.continueTitle.localized() }
    var priceDetailsTitle: String { LocalizedKey.priceDetails.localized() }
    var okTitle: String { LocalizedKey.ok.localized() }

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

    /// Selects the option and allocates it in the cart. If the cart cannot be updated,
    /// the error is shown and the selection returns to the option the cart holds.
    func select(_ option: ProductOption) {
        guard isAvailable(option), option != selectedOption else { return }
        selectedOption = option
        pendingSelections += 1
        Task {
            let error = await allocateOption(option)
            pendingSelections -= 1
            if let error {
                // A later choice may already be selected; only undo this one.
                if selectedOption == option {
                    selectedOption = allocatedOption
                }
                errorMessage = error
            } else {
                allocatedOption = option
                cartPrice = currentCartPrice()
            }
        }
    }

    /// e.g. "+840 SAR", converted to the selected currency.
    func priceText(_ option: ProductOption) -> String {
        CurrencyManager.shared.formatPrice(value: option.price ?? 0, currencyCode: option.currency ?? cartPrice?.currency)
    }

    // MARK: - Total

    /// Sections of the cart price that have something to show.
    var breakdownSections: [PriceBreakdownSection] {
        (cartPrice?.breakdown ?? []).filter { section in
            !(section.items ?? []).isEmpty || section.amount != nil
        }
    }

    /// The selected option's cost for the whole group.
    func upgradeAmount(visitorCount: Int) -> Double {
        (selectedOption?.price ?? 0) * Double(visitorCount)
    }

    /// The cart total, which already includes the allocated option; `nil` until the price is known.
    func totalAmountText(visitorCount: Int) -> String? {
        guard let cartPrice else { return nil }
        return CurrencyManager.shared.formatPrice(value: cartPrice.finalAmount, currencyCode: cartPrice.currency)
    }

    /// e.g. "+ 1,680 SAR • Cabin upgrade"; `nil` while the included option is selected.
    func upgradeDetailText(visitorCount: Int) -> String? {
        let amount = upgradeAmount(visitorCount: visitorCount)
        guard amount > 0 else { return nil }
        return "+ \(CurrencyManager.shared.formatPrice(value: amount, currencyCode: cartPrice?.currency)) • \(title)"
    }

    private static func isIncluded(_ option: ProductOption) -> Bool {
        (option.price ?? 0) == 0
    }
}
