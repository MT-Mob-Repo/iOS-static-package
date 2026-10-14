//
//  PackagesListViewModel.swift
//  AlmatarStaticPackageSDK
//

import Foundation

@MainActor
final class PackagesListViewModel: ObservableObject {
    let section: PackagesSection

    /// The package whose booking request is in flight; its "Book" button shows a loader.
    @Published private(set) var bookingPackageId: String?
    /// Set after a successful booking to show that package's details.
    @Published var bookedPackageId: String?
    /// Set when booking fails; shown as an alert.
    @Published var bookingErrorMessage: String?

    private let repository: StaticPackagesRepositoryProtocol

    init(section: PackagesSection, repository: StaticPackagesRepositoryProtocol) {
        self.section = section
        self.repository = repository
    }

    // MARK: - Strings

    var startingFromTitle: String { LocalizedKey.startingFrom.localized() }
    var bookTitle: String { LocalizedKey.book.localized() }
    var okTitle: String { LocalizedKey.ok.localized() }
    private var genericErrorMessage: String { LocalizedKey.genericError.localized() }

    // MARK: - Formatting

    /// e.g. "RECORD-BREAKING COASTERS" or "FAMILY FUN • WATER PARK".
    func categoriesText(_ package: PackageSummary) -> String? {
        let categories = package.categories.compactMap { Optional($0).nonEmpty }
        guard !categories.isEmpty else { return nil }
        return categories.joined(separator: " • ").uppercased()
    }

    /// e.g. "SAR 1,250"; `nil` when the package has no price.
    func priceText(_ package: PackageSummary) -> String? {
        guard let price = package.startingPrice else { return nil }
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        let amount = formatter.string(from: price as NSDecimalNumber) ?? "\(price)"
        guard let currency = package.currency.nonEmpty else { return amount }
        return "\(currency) \(amount)"
    }

    func imageURL(_ package: PackageSummary) -> URL? {
        package.images.lazy.compactMap { Optional($0).nonEmpty.flatMap(URL.init(string:)) }.first
    }

    // MARK: - Actions

    var isBooking: Bool { bookingPackageId != nil }

    func isBooking(_ package: PackageSummary) -> Bool {
        bookingPackageId == package.packageId
    }

    /// Creates a cart for the package, then shows its details.
    func bookTapped(_ package: PackageSummary) async {
        guard !isBooking else { return }
        bookingPackageId = package.packageId
        defer { bookingPackageId = nil }

        do {
            _ = try await repository.bookPackage(packageId: package.packageId)
            bookedPackageId = package.packageId
        } catch is CancellationError {
            return
        } catch {
            let apiMessages = (error as? NetworkError)?.apiMessages ?? []
            bookingErrorMessage = apiMessages.isEmpty ? genericErrorMessage : apiMessages.joined(separator: "\n")
        }
    }
}
