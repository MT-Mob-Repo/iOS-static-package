//
//  PackageAsset.swift
//  AlmatarStaticPackageSDK
//

import Foundation

/// Named images shipped in `Resources/Assets.xcassets`.
/// Drop PNG files into the matching `.imageset` folders using these names.
enum PackageAsset {
    /// Header carousel slides (left → right).
    static let carouselImageNames = [
        "package_carousel_1",
        "package_carousel_1",
        "package_carousel_1",
        "package_carousel_1"
    ]

    /// Illustration of the "Remove visitor" confirmation.
    static let removeVisitorIcon = "remove-visitor-icon"
}
