// swift-tools-version: 6.2
import PackageDescription

// AppChangelog: geteilte Changelog-Anzeige fuer alle Swift-Projekte.
// Parst eine CHANGELOG.md im Format "Keep a Changelog" und rendert sie als
// SwiftUI-View. Zusaetzlich ein "Was ist neu"-Sheet, das nach einem
// Versionssprung einmalig die seither hinzugekommenen Aenderungen zeigt.
// Gruppiert wird ausschliesslich nach Marketing-Version (major.minor.patch),
// nie nach Build-Nummer.
let package = Package(
    name: "AppChangelog",
    defaultLocalization: "de",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: "AppChangelog", targets: ["AppChangelog"])
    ],
    targets: [
        .target(name: "AppChangelog"),
        .testTarget(name: "AppChangelogTests", dependencies: ["AppChangelog"])
    ]
)
