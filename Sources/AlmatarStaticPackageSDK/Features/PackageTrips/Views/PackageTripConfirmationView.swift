//
//  PackageTripConfirmationView.swift
//  AlmatarStaticPackageSDK
//
//  The booking confirmation opened from My Trips, with the shared SDK toolbar
//  (title and back button).
//

import SwiftUI

struct PackageTripConfirmationView: View {
    let orderId: String
    /// When set, called on back / "Go to My Trips" instead of the SwiftUI dismiss.
    var onBack: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AlmatarStaticPackageSDK.shared.makeBookingConfirmationView(
            id: orderId,
            // The user came from My Trips, so this goes back to it.
            onGoToMyTrips: { goBack() },
            onBackToHome: { AlmatarStaticPackageSDK.shared.onBackToHome?() }
        )
        .defaultToolbar(
            title: LocalizedKey.tripConfirmationTitle.localized(),
            shouldDismiss: onBack == nil,
            onBack: onBack
        )
    }

    private func goBack() {
        if let onBack {
            onBack()
        } else {
            dismiss()
        }
    }
}
