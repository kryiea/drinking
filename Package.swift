// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "YinzhiCorePackage",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "YinzhiCore", targets: ["YinzhiCore"]),
    ],
    targets: [
        .target(
            name: "YinzhiCore",
            path: "Sources/YinzhiCore"
        ),
        .testTarget(
            name: "YinzhiCoreTests",
            dependencies: ["YinzhiCore"],
            path: "Tests/YinzhiCoreTests"
        ),
    ]
)
