//
//  StaticPackageTheme.swift
//  AlmatarStaticPackageSDK
//

import UIKit

/// The host app's theme mode.
/// The SDK applies it to the windows it creates itself (e.g. popups), which don't get
/// the `overrideUserInterfaceStyle` the host app sets on its own windows.
public enum StaticPackageTheme: String, CaseIterable, Sendable {
    case light
    case dark

    var isDark: Bool { self == .dark }

    var userInterfaceStyle: UIUserInterfaceStyle { isDark ? .dark : .light }
}
