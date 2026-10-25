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
    dependencies: [
        .package(url: "https://github.com/MT-Mob-Repo/iOS-Almatar-System-Design-SDK", .upToNextMajor(from: "1.0.7"))
    ],
    targets: [
        .target(
            name: "AlmatarStaticPackageSDK",
            dependencies: [
                .product(name: "AlmatarSystemDesignSDK", package: "iOS-Almatar-System-Design-SDK")
            ],
            path: "Sources/AlmatarStaticPackageSDK",
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
