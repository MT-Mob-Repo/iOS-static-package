//
//  ToolbarAction.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// A trailing toolbar button that can be shown, hidden, and wired to an action at runtime.
struct ToolbarAction: Identifiable {
    let id: String
    let systemImage: String
    var isVisible: Bool
    let action: () -> Void

    init(
        id: String = UUID().uuidString,
        systemImage: String,
        isVisible: Bool = true,
        action: @escaping () -> Void
    ) {
        self.id = id
        self.systemImage = systemImage
        self.isVisible = isVisible
        self.action = action
    }
}
