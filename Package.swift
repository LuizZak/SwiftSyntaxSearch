// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "SwiftSyntaxSearch",
    products: [
        .library(
            name: "SwiftSyntaxSearch",
            targets: ["SwiftSyntaxSearch"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "0.50700.0"),
    ],
    targets: [
        .target(
            name: "SwiftSyntaxSearch",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "SwiftSyntaxSearchTests",
            dependencies: [
                "SwiftSyntaxSearch",
            ]
        ),
    ]
)
