// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Game2048Core",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "Game2048Core", targets: ["Game2048Core"])
    ],
    targets: [
        .target(name: "Game2048Core"),
        .testTarget(name: "Game2048CoreTests", dependencies: ["Game2048Core"])
    ]
)
