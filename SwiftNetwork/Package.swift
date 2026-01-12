// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftNetwork",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftNetwork",
            targets: ["SwiftNetwork"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            from: "1.3.0"
        )
    ],
    targets: [
        .target(
            name: "SwiftNetwork",
            path: "Sources/SwiftNetwork"
        ),
        .testTarget(
            name: "SwiftNetworkTests",
            dependencies: ["SwiftNetwork"],
            path: "Tests/SwiftNetworkTests"
        )
    ]
)
