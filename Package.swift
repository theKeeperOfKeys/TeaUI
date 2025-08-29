// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TeaUI",
	platforms: [
		.macOS(.v13)
	],
    products: [
        .library(
            name: "TeaUI",
            targets: ["TeaUI"]
		),
    ],
    targets: [
        .target(name: "TeaUI"),
		.executableTarget(
			name: "TeaUIExample",
			dependencies: ["TeaUI"]
		)
    ]
)
