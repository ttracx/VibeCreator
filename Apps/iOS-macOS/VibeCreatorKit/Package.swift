// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VibeCreatorKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "VibeCreatorKit",
            targets: ["VibeCreatorKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "VibeCreatorKit",
            dependencies: [
                "Alamofire",
                "KeychainAccess"
            ]
        ),
        .testTarget(
            name: "VibeCreatorKitTests",
            dependencies: ["VibeCreatorKit"]
        ),
    ]
)
