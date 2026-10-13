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

extension PackageScheduleItem {
    /// Sample items for previews, covering every optional combination.
    static let mockItems: [PackageScheduleItem] = [
        // Tag + status, card without image.
        PackageScheduleItem(
            id: "transfer",
            title: "Airport to Hotel Transfer",
            description: "Arrive at King Abdulaziz International Airport in Jeddah. Our dedicated shuttle service will transport you to your hotel near the Haram in Makkah Arrive at King Abdulaziz International Airport in Jeddah. Our dedicated shuttle service will transport you to your hotel near the Haram in Makkah Arrive at King Abdulaziz International Airport in Jeddah. Our dedicated shuttle service will transport you to your hotel near the Haram in Makkah Arrive at King Abdulaziz International Airport in Jeddah. Our dedicated shuttle service will transport you to your hotel near the Haram in Makkah.",
            tag: PackageScheduleTag(icon: "ticket", title: "Ticket"),
            statusLabel: "Included",
            card: PackageScheduleCard(
                imageUrl: nil,
                title: "Airport to Hotel Transfer",
                rating: nil,
                details: nil,
                description: "Arrive at King Abdulaziz International Airport in Jeddah. Our dedicated shuttle service will transport you to your hotel near the Haram in Makkah.",
                room: nil,
                statusLabel: "Included"
            )
        ),
        // No tag row, card with image + description.
        PackageScheduleItem(
            id: "splash",
            title: "Splash Island & Kids' Play",
            description: "Cool off at the water park or explore the interactive play zones designed for younger adventurers. Cool off at the water park or explore the interactive play zones designed for younger adventurers. Cool off at the water park or explore the interactive play zones designed for younger adventurers. Cool off at the water park or explore the interactive play zones designed for younger adventurers.",
            tag: nil,
            statusLabel: nil,
            card: PackageScheduleCard(
                imageUrl: "https://images.almatar.com/packages/splash-island.jpg",
                title: "Splash Island & Kids' Play",
                rating: nil,
                details: nil,
                description: "Cool off at the water park or explore the interactive play zones designed for younger adventurers. Cool off at the water park or explore the interactive play zones designed for younger adventurers. Cool off at the water park or explore the interactive play zones designed for younger adventurers. Cool off at the water park or explore the interactive play zones designed for younger adventurers.",
                room: nil,
                statusLabel: "Included"
            )
        ),
        // Hotel: image, rating, location, date and room.
        PackageScheduleItem(
            id: "ritz",
            title: "The Ritz-Carlton, Riyadh",
            description: "Cool off at the water park or explore the interactive play zones designed for younger adventurers.",
            tag: PackageScheduleTag(icon: "building.2", title: "Stay"),
            statusLabel: "Included",
            card: PackageScheduleCard(
                imageUrl: "https://images.almatar.com/packages/ritz-riyadh.jpg",
                title: "The Ritz-Carlton, Riyadh",
                rating: 4.9,
                details: [
                    PackageScheduleInfo(icon: "mappin.and.ellipse", text: "Palace-style luxury • Riyadh"),
                    PackageScheduleInfo(icon: "calendar", text: "16–24 Jul • 5 nights")
                ],
                description: nil,
                room: PackageScheduleRoom(title: "Room • Deluxe City View", subtitle: "1 king bed • sleeps 2"),
                statusLabel: "Included"
            )
        ),
        // Tag + status, card with image + description.
        PackageScheduleItem(
            id: "makkah",
            title: "Makkah hotels",
            description: "Enjoy breathtaking views of the Kaaba directly from your room. Located just 200m from the holy courtyard.",
            tag: PackageScheduleTag(icon: "ticket", title: "Ticket"),
            statusLabel: "Included",
            card: PackageScheduleCard(
                imageUrl: "https://images.almatar.com/packages/makkah-hotels.jpg",
                title: "Makkah hotels",
                rating: nil,
                details: nil,
                description: "Enjoy breathtaking views of the Kaaba directly from your room. Located just 200m from the holy courtyard.",
                room: nil,
                statusLabel: "Included"
            )
        ),
        // Hotel without image, rating or date; room without subtitle; no footer status.
        PackageScheduleItem(
            id: "jeddah",
            title: "Jeddah Hilton",
            description: nil,
            tag: PackageScheduleTag(icon: "building.2", title: "Stay"),
            statusLabel: nil,
            card: PackageScheduleCard(
                imageUrl: nil,
                title: "Jeddah Hilton",
                rating: nil,
                details: [PackageScheduleInfo(icon: "mappin.and.ellipse", text: "Corniche • Jeddah")],
                description: nil,
                room: PackageScheduleRoom(title: "Room • Sea View", subtitle: nil),
                statusLabel: nil
            )
        ),
        // Text-only step, status without tag.
        PackageScheduleItem(
            id: "free-time",
            title: "Free time in Riyadh",
            description: "Explore the city at your own pace.",
            tag: nil,
            statusLabel: "Optional",
            card: nil
        )
    ]
}
