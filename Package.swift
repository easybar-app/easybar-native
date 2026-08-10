// swift-tools-version: 5.10

import PackageDescription

let package = Package(
  name: "EasyBarNative",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "EasyBarNative", targets: ["EasyBarNativeApp"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/easybar-app/easybar-kit",
      from: "0.2.0"
    )
  ],
  targets: [
    .executableTarget(
      name: "EasyBarNativeApp",
      dependencies: [
        .product(name: "EasyBarKit", package: "easybar-kit"),
        .product(name: "EasyBarShared", package: "easybar-kit"),
      ],
      path: "Sources/EasyBarNativeApp",
      exclude: [
        "Info.plist"
      ],
      swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
      ]
    ),
    .testTarget(
      name: "EasyBarNativeAppTests",
      dependencies: [
        "EasyBarNativeApp",
        .product(name: "EasyBarKit", package: "easybar-kit"),
        .product(name: "EasyBarShared", package: "easybar-kit"),
      ],
      path: "Tests/EasyBarNativeAppTests",
      swiftSettings: [
        .enableUpcomingFeature("StrictConcurrency")
      ]
    ),
  ]
)
