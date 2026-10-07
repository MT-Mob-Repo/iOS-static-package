//
//  DesignTokens.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI

/// Spacing values matching the Almatar app design system.
enum Spacing {
    static let xSmall: CGFloat = 8
    static let medium: CGFloat = 16
    static let screenHorizontal: CGFloat = 16
    static let screenBottom: CGFloat = 16
}

enum Typography {
    static let title = Font.system(size: 18, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let button = Font.system(size: 16, weight: .semibold)
}
