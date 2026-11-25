// swift-tools-version: 6.0
// MailZenKit: the core of the iOS app, without any user interface. The analysis
// engine, the content in three languages, the parsing of emails (.eml) and the IMAP
// client that watches a mailbox. Tested on Linux and on macOS (`swift test`).

import PackageDescription

let package = Package(
    name: "MailZenKit",
    defaultLocalization: "fr",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "MailZenKit", targets: ["MailZenKit"])
    ],
    targets: [
        .target(name: "MailZenKit"),
        .testTarget(name: "MailZenKitTests", dependencies: ["MailZenKit"]),
    ],
    swiftLanguageModes: [.v6]
)
