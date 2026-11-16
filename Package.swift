// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "Jot",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "JotCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .executableTarget(name: "Jot", dependencies: ["JotCore"]),
        .executableTarget(name: "jot-cli", dependencies: ["JotCore"]),
        .testTarget(name: "JotCoreTests", dependencies: ["JotCore"]),
    ],
    swiftLanguageModes: [.v5]
)
