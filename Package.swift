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
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.29.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Quay",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            exclude: [
            	"Protobuf/PBContainer.proto"
            ]
        ),
        .testTarget(
            name: "QuayTests",
            dependencies: ["Quay"]
        ),
    ]
)
