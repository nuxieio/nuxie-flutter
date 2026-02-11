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
  dependencies: [
    .package(url: "https://github.com/nuxieio/nuxie-ios.git", branch: "main")
  ],
  targets: [
    .target(
      name: "nuxie_flutter_native",
      dependencies: [
        .product(name: "Nuxie", package: "nuxie-ios")
      ],
      path: "Sources/nuxie_flutter_native",
      sources: [
        "NuxieBridge.g.swift",
        "NuxieFlutterNativePlugin.swift"
      ]
    )
  ]
)
