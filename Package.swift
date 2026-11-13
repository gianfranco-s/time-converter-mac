// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ZoneGrid",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "ZoneGrid", path: "Sources/ZoneGrid")
    ]
)
