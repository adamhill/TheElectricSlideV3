// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SlideRuleCoreV3",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SlideRuleCoreV3",
            targets: ["SlideRuleCoreV3"]
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SlideRuleCoreV3"
        ),
        .testTarget(
            name: "SlideRuleCoreV3Tests",
            dependencies: ["SlideRuleCoreV3"]
        ),
    ]
)
