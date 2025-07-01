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
        // Local dependency for testing
        .package(path: "../..")
    ],
    targets: [
        .executableTarget(
            name: "OnairosSDKDemo",
            dependencies: [
                .product(name: "OnairosSDK", package: "Onairos-Swift")
            ]
        )
    ]
) 