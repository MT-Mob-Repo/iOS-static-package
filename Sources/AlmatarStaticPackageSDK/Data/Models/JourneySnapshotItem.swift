//
//  JourneySnapshotItem.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// One highlight in the package "Journey Snapshot" (e.g. location, duration, group size).
struct JourneySnapshotItem: Codable, Sendable, Identifiable, Hashable {
    let id: String
    /// Remote image URL, or an SF Symbol name.
    let icon: String
    let title: String
    /// Takes the whole row instead of half of it.
    let isFullWidth: Bool

    enum CodingKeys: String, CodingKey {
        case id, icon, title, isFullWidth
    }

    init(id: String, icon: String, title: String, isFullWidth: Bool = false) {
        self.id = id
        self.icon = icon
        self.title = title
        self.isFullWidth = isFullWidth
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        icon = try container.decode(String.self, forKey: .icon)
        title = try container.decode(String.self, forKey: .title)
        isFullWidth = try container.decodeIfPresent(Bool.self, forKey: .isFullWidth) ?? false
    }
}

extension JourneySnapshotItem {
    /// Sample items for previews.
    static let mockItems: [JourneySnapshotItem] = [
        JourneySnapshotItem(id: "location", icon: "map", title: "Qiddiya City, SA", isFullWidth: true),
        JourneySnapshotItem(id: "duration", icon: "moon", title: "1 Day Pass"),
        JourneySnapshotItem(id: "pass", icon: "star", title: "1 Day Pass"),
        JourneySnapshotItem(id: "group", icon: "person.2", title: "Group: 4-6"),
        JourneySnapshotItem(id: "thrill", icon: "clock.arrow.circlepath", title: "Thrill Level: Max")
    ]
}
