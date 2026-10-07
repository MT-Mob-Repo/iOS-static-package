//
//  AppLanguage.swift
//  AlmatarStaticPackageSDK
//

import SwiftUI

public enum AppLanguage: String, CaseIterable, Sendable {
    case english = "en"
    case arabic  = "ar"

    var isRTL: Bool { self == .arabic }
    var layoutDirection: LayoutDirection { isRTL ? .rightToLeft : .leftToRight }
}
