// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "nuxie_flutter_native",
  platforms: [
    .iOS(.v15)
  ],
  products: [
    .library(name: "nuxie_flutter_native", targets: ["nuxie_flutter_native"])
  ],
  dependencies: [],
  targets: [
    .target(
      name: "nuxie_flutter_native",
      dependencies: [],
      path: "Sources/nuxie_flutter_native"
    )
  ]
)
