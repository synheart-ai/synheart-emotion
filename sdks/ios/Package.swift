// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SynheartEmotion",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .watchOS(.v6),
        .tvOS(.v13)
    ],
    products: [
        .library(
            name: "SynheartEmotion",
            targets: ["SynheartEmotion"]
        ),
    ],
    targets: [
        .target(
            name: "SynheartEmotion",
            dependencies: []
        ),
        .testTarget(
            name: "SynheartEmotionTests",
            dependencies: ["SynheartEmotion"]
        ),
    ]
)
