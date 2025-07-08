// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "OnairosSDKDemo",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .executable(name: "OnairosSDKDemo", targets: ["OnairosSDKDemo"])
    ],
    dependencies: [
        // Remote dependency - SDK hosted on GitHub
        .package(url: "https://github.com/YOUR_USERNAME/onairos-swift-sdk.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "OnairosSDKDemo",
            dependencies: [
                .product(name: "OnairosSDK", package: "onairos-swift-sdk")
            ]
        )
    ]
) 