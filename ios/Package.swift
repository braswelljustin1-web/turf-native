// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "TurfCore", platforms: [.macOS(.v13), .iOS(.v17)],
    products: [.library(name: "TurfCore", targets: ["TurfCore"])],
    targets: [.target(name: "TurfCore", path: "Core"), .testTarget(name: "TurfCoreTests", dependencies: ["TurfCore"], path: "Tests")])
