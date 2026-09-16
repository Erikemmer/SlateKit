// swift-tools-version: 6.0
// SlateKit: the look of a slate-grey, Final-Cut-shaped desktop app, as reusable
// SwiftUI parts. Shared by Selector (photo culling) and Shelf (eBook manager).
//
// Everything here is about appearance and layout. Nothing in it knows about
// photos, books, or any other subject matter – that is the line that decides
// whether a view belongs in this package or in the app.
import PackageDescription

let package = Package(
    name: "SlateKit",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SlateKit", targets: ["SlateKit"])
    ],
    targets: [
        .target(
            name: "SlateKit",
            path: "Sources/SlateKit",
            resources: [.process("Resources")],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SlateKitTests",
            dependencies: ["SlateKit"],
            path: "Tests/SlateKitTests",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
