

// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OnairosSDK",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .library(
            name: "OnairosSDK",
            targets: ["OnairosSDK"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/socketio/socket.io-client-swift", from: "16.0.0"),
        .package(url: "https://github.com/google/GoogleSignIn-iOS", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "OnairosSDK",
            dependencies: [
                .product(name: "SocketIO", package: "socket.io-client-swift"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
            ],
            path: "Sources/OnairosSDK",
            resources: [
                .copy("Resources")
            ]
        ),
        .testTarget(
            name: "OnairosSDKTests",
            dependencies: ["OnairosSDK"],
            path: "Tests/OnairosSDKTests"
        ),
    ]
) 