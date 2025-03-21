// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Quay",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Quay",
            targets: ["Quay"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.29.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.4"),
        .package(url: "https://github.com/f-meloni/SwiftBrotli.git", branch: "master")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Quay",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "CryptoSwift", package: "cryptoswift"),
                .product(name: "SwiftBrotli", package: "SwiftBrotli")
            ],
            exclude: [
                "Protobuf/PBContainer.proto",
                "Protobuf/PBFiles.proto"
            ]
        ),
        .testTarget(
            name: "QuayTests",
            dependencies: ["Quay"]
        ),
    ]
)
