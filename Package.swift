// swift-tools-version: 5.10

import PackageDescription

let strictConcurrencySettings: [SwiftSetting] = [
  .enableUpcomingFeature("StrictConcurrency")
]

let package = Package(
  name: "EasyBarNative",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .executable(name: "EasyBarNative", targets: ["EasyBarNativeApp"]),
    .executable(name: "EasyBarNativeCtl", targets: ["EasyBarNativeCtl"]),
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
      swiftSettings: strictConcurrencySettings
    ),
    .executableTarget(
      name: "EasyBarNativeCtl",
      dependencies: [
        .product(name: "EasyBarShared", package: "easybar-kit")
      ],
      path: "Sources/EasyBarNativeCtl",
      swiftSettings: strictConcurrencySettings
    ),
    .testTarget(
      name: "EasyBarNativeAppTests",
      dependencies: [
        "EasyBarNativeApp",
        .product(name: "EasyBarKit", package: "easybar-kit"),
        .product(name: "EasyBarShared", package: "easybar-kit"),
      ],
      path: "Tests/EasyBarNativeAppTests",
      swiftSettings: strictConcurrencySettings
    ),
  ]
)
