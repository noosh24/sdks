// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Noosh24",
    platforms: [
        .macOS(.v15),
        .iOS(.v16),
    ],
    products: [
        .library(name: "Noosh24", targets: ["Noosh24"])
    ],
    targets: [
        .target(name: "Noosh24"),
        .testTarget(name: "Noosh24Tests", dependencies: ["Noosh24"]),
    ],
    swiftLanguageModes: [.v6]
)
