// swift-tools-version:6.0
// AutoGit - Automatic commit message generation

import PackageDescription

let package = Package(
    name: "AutoGit",
    platforms: [.macOS(.v15)],
    products: [.executable(name: "autogit", targets: ["AutoGit"])],
    targets: [.executableTarget(name: "AutoGit", swiftSettings: [.swiftLanguageMode(.v6)])]
)
