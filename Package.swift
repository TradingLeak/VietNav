//
//  Package.swift (SPM manifest - optional)
//  VietNav uses MapKit only; no external dependencies required.
//

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VietNav",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "VietNav", targets: ["VietNav"])
    ],
    dependencies: [],
    targets: [
        .target(name: "VietNav", dependencies: [])
    ]
)
