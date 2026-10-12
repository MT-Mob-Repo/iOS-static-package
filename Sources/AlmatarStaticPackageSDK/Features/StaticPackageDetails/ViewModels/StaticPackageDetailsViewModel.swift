//
//  StaticPackageDetailsViewModel.swift
//  AlmatarStaticPackageSDK
//

import Foundation

@MainActor
final class StaticPackageDetailsViewModel: ObservableObject {
    enum State {
        case idle
        case loading
        case loaded(PackageDetails)
        case failed(message: String)
    }

    @Published private(set) var state: State = .idle

    // MARK: - Strings
    var goToPaymentTitle: String { LocalizedKey.goToPayment.localized() }
    var journeySnapshotTitle: String { LocalizedKey.journeySnapshot.localized() }
    var parkHighlightsTitle: String { LocalizedKey.parkHighlights.localized() }
    var packageScheduleTitle: String { LocalizedKey.packageSchedule.localized() }
    var retryTitle: String { LocalizedKey.retry.localized() }
    private var genericErrorMessage: String { LocalizedKey.genericError.localized() }

    var packageDetails: PackageDetails? {
        if case .loaded(let details) = state { return details }
        return nil
    }

    private let packageId: String
    private let repository: StaticPackagesRepositoryProtocol
    private let onGoToPayment: () -> Void

    init(
        packageId: String,
        repository: StaticPackagesRepositoryProtocol,
        onGoToPayment: @escaping () -> Void
    ) {
        self.packageId = packageId
        self.repository = repository
        self.onGoToPayment = onGoToPayment
    }

    func loadPackageDetails() async {
        state = .loading
        do {
            let details = try await repository.fetchPackageDetails(packageId: packageId)
            state = .loaded(details)
        } catch is CancellationError {
            state = .idle
        } catch {
            let apiMessages = (error as? NetworkError)?.apiMessages ?? []
            state = .failed(message: apiMessages.isEmpty ? genericErrorMessage : apiMessages.joined(separator: "\n"))
        }
    }

    func goToPaymentTapped() {
        guard packageDetails != nil else { return }
        onGoToPayment()
    }
}
