// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ClaudeLauncher",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ClaudeLauncher",
            path: "Sources/ClaudeLauncher"
        )
    ]
)
