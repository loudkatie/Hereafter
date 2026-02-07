// swift-tools-version: 5.9
// Hereafter — Leave a message. Find it hereafter.

import PackageDescription

let package = Package(
    name: "Hereafter",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Hereafter",
            targets: ["Hereafter"]
        ),
    ],
    targets: [
        .target(
            name: "Hereafter",
            path: "Hereafter"
        ),
    ]
)
