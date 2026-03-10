// swift-tools-version: 6.1

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
            path: "SwiftNetwork/Sources/SwiftNetwork"
        ),
        .testTarget(
            name: "SwiftNetworkTests",
            dependencies: ["SwiftNetwork"],
            path: "SwiftNetwork/Tests/SwiftNetworkTests"
        )
    ]
)
