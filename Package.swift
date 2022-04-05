// swift-tools-version:5.3
// When used via SPM the minimum Swift version is 5.3 because we need support for resources

import Foundation
import PackageDescription

let package = Package(
    name: "StreamChat",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v11), .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "StreamChat",
            targets: ["StreamChat"]
        ),
        .library(
            name: "StreamChatUI",
            targets: ["StreamChatUI"]
        )
    ],
    dependencies: [
        // StreamChat
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.0"),
        
        // StreamChatUI
        .package(url: "https://github.com/kean/Nuke.git", from: "10.0.0"),
        .package(url: "https://github.com/kirualex/SwiftyGif.git", from: "5.4.1"),
        .package(url: "https://github.com/EFPrefix/EFQRCode.git", from: "6.2.0")
    ],
    targets: [
        .target(
            name: "StreamChat",
            dependencies: ["Starscream"],
            exclude: ["README.md", "Info.plist"],
            resources: [.copy("Database/StreamChatModel.xcdatamodeld")]
        ),
        .target(
            name: "StreamChatUI",
            dependencies: ["StreamChat"],
            exclude: ["README.md", "Info.plist", "Generated/L10n_template.stencil"],
            resources: [.process("Resources")]
        )
    ]
)
