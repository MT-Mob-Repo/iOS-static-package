//
//  PackageScheduleItem.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// One step in the package "Schedule" timeline (e.g. Airport to Hotel Transfer).
struct PackageScheduleItem: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let title: String
    let description: String?
    /// Badge under the description, e.g. "Ticket" or "Stay".
    let tag: PackageScheduleTag?
    /// Label at the end of the tag row, e.g. "Included".
    let statusLabel: String?
    /// Detail card under the step; `nil` shows the step as text only.
    let card: PackageScheduleCard?
}

struct PackageScheduleTag: Codable, Sendable, Hashable {
    /// Remote image URL, or an SF Symbol name.
    let icon: String?
    let title: String
}

struct PackageScheduleCard: Codable, Sendable, Hashable {
    let imageUrl: String?
    let title: String
    /// Shown next to the title, e.g. a hotel rating of 4.9.
    let rating: Double?
    /// Icon + text lines under the title, e.g. location or dates.
    let details: [PackageScheduleInfo]?
    let description: String?
    let room: PackageScheduleRoom?
    /// Label in the card footer, e.g. "Included".
    let statusLabel: String?
    /// Flight legs; when set the card shows the flight layout instead of the generic one.
    var flight: PackageScheduleFlight? = nil
}

struct PackageScheduleFlight: Codable, Sendable, Hashable {
    let legs: [PackageScheduleFlightLeg]
    /// Shows the "Change upgrade" button under the legs.
    let isUpgradeAvailable: Bool
}

struct PackageScheduleFlightLeg: Codable, Sendable, Hashable {
    /// Shows the "Upgraded" badge above the leg.
    let isUpgraded: Bool
    let airlineLogoUrl: String?
    /// e.g. "Jeddah → Riyadh".
    let route: String
    /// e.g. "SV-1430 • Premium Economy".
    let subtitle: String?
    /// e.g. "08:30".
    let departureTime: String?
    /// e.g. "Barcelona (BCN)".
    let departureLocation: String
    let arrivalTime: String?
    let arrivalLocation: String
    /// e.g. "1h 45m • Direct".
    let durationInfo: String?
}

struct PackageScheduleInfo: Codable, Sendable, Hashable {
    /// Remote image URL, or an SF Symbol name.
    let icon: String
    let text: String
}

struct PackageScheduleRoom: Codable, Sendable, Hashable {
    /// e.g. "Room • Deluxe City View".
    let title: String
    /// e.g. "1 king bed • sleeps 2".
    let subtitle: String?
}
