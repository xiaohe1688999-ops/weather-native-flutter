// swift-tools-version: 5.9
import PackageDescription

let package = Package(name: "WeatherCore", platforms: [.iOS(.v15), .macOS(.v13)],
    products: [.library(name: "WeatherCore", targets: ["WeatherCore"])],
    targets: [.target(name: "WeatherCore"), .testTarget(name: "WeatherCoreTests", dependencies: ["WeatherCore"])])
