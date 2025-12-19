// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftNetwork",
    platforms: [
        .iOS(.v16),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SwiftNetwork",
            targets: ["SwiftNetwork"]
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
