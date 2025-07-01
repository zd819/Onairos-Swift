// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "OnairosSDKTestApp",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        .executable(name: "TestApp", targets: ["TestApp"])
    ],
    dependencies: [
        // Add your published package here
        .package(url: "https://github.com/YOUR_USERNAME/onairos-swift-sdk.git", from: "1.0.0"),
        // Or for local testing:
        // .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "TestApp",
            dependencies: [
                .product(name: "OnairosSDK", package: "onairos-swift-sdk")
            ]
        )
    ]
) 