// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Quill",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Quill", targets: ["Quill"])
    ],
    dependencies: [
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", exact: "1.9.4"),
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.2"),
        .package(url: "https://github.com/jamesrochabrun/SwiftAnthropic", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Quill",
            dependencies: [
                "KeyboardShortcuts",
                "KeychainAccess",
                "SwiftAnthropic",
            ],
            path: "Quill",
            exclude: ["Info.plist", "Quill.entitlements"]
        )
    ]
)
