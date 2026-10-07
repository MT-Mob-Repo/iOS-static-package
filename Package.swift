// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AlmatarStaticPackageSDK",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "AlmatarStaticPackageSDK",
            targets: ["AlmatarStaticPackageSDK"]
        ),
    ],
    targets: [
        .target(
            name: "AlmatarStaticPackageSDK",
            path: "Sources/AlmatarStaticPackageSDK",
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
