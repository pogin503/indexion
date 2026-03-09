// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MySwiftPackage",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: "MySwiftPackage", targets: ["MySwiftPackage"]),
        .executable(name: "my-cli", targets: ["CLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.5.0"),
        .package(url: "https://github.com/vapor/vapor", from: "4.89.0")
    ],
    targets: [
        .target(
            name: "MySwiftPackage",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .executableTarget(
            name: "CLI",
            dependencies: [
                "MySwiftPackage",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .testTarget(
            name: "MySwiftPackageTests",
            dependencies: ["MySwiftPackage"]
        )
    ]
)
