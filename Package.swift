// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AS_GRDBSwiftUI",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "AS_GRDBSwiftUI",
            targets: ["AS_GRDBSwiftUI"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "GRDB", url: "https://github.com/groue/GRDB.swift", from: "4.12.1"),
        .package(url: "https://github.com/groue/GRDBCombine", from: "0.8.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "AS_GRDBSwiftUI",
            dependencies: ["GRDB", "GRDBCombine"]
        ),
    ]
)
