//
//  LocalizedKey.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Keys in `Localizable.xcstrings` (en / ar).
enum LocalizedKey: String {
    // MARK: Static Package Details
    case goToPayment = "static_package_details.go_to_payment"
    case journeySnapshot = "static_package_details.journey_snapshot"
    case parkHighlights = "static_package_details.park_highlights"
    case packageSchedule = "static_package_details.package_schedule"
    case includedServices = "static_package_details.included_services"
    case includedServicesSubtitle = "static_package_details.included_services_subtitle"
    case includedInYourPass = "static_package_details.included_in_your_pass"

    // MARK: Package Booking Confirmation
    case bookingConfirmedTitle = "package_booking_confirmation.title"
    case bookingConfirmedSubtitle = "package_booking_confirmation.subtitle"
    case bookingId = "package_booking_confirmation.booking_id"
    case copyBookingId = "package_booking_confirmation.copy_booking_id"
    case packageSummary = "package_booking_confirmation.package_summary"
    case package = "package_booking_confirmation.package"
    case destination = "package_booking_confirmation.destination"
    case duration = "package_booking_confirmation.duration"
    case tier = "package_booking_confirmation.tier"
    case packageIncludes = "package_booking_confirmation.package_includes"
    case paymentDetails = "package_booking_confirmation.payment_details"
    case totalPaid = "package_booking_confirmation.total_paid"
    case cancellationPolicy = "package_booking_confirmation.cancellation_policy"
    case freeCancellation = "package_booking_confirmation.free_cancellation"
    case nonRefundable = "package_booking_confirmation.non_refundable"
    case refundPercentage = "package_booking_confirmation.refund_percentage"
    case goToMyTrips = "package_booking_confirmation.go_to_my_trips"
    case backToHome = "package_booking_confirmation.back_to_home"

    // MARK: Common
    case genericError = "common.generic_error"
    case retry = "common.retry"
    case readMore = "common.read_more"
    case readLess = "common.read_less"

    /// Localized value in the language currently configured in the SDK, independent of the device language.
    @MainActor
    func localized() -> String {
        let language = AlmatarStaticPackageSDK.shared.configuration.language
        return NSLocalizedString(rawValue, bundle: language.bundle, comment: "")
    }

    /// Localized format string filled with `arguments`.
    @MainActor
    func localized(_ arguments: CVarArg...) -> String {
        String(format: localized(), arguments: arguments)
    }
}

private extension AppLanguage {
    /// The `.lproj` bundle for this language inside the SDK, falling back to the SDK bundle.
    var bundle: Bundle {
        guard let path = Bundle.module.path(forResource: rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .module
        }
        return bundle
    }
}
