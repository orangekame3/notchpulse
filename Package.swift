// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NotchCPUMonitor",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "NotchCPUMonitor",
            path: "Sources/NotchCPUMonitor",
            exclude: ["Info.plist", "NotchPulse.icns"]
        )
    ]
)
