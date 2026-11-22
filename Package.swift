// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "swift-bessel",
    platforms: [.macOS(.v27), .iOS(.v27), .tvOS(.v27), .watchOS(.v27), .visionOS(.v27)],
    products: [.library(name: "Bessel", targets: ["Bessel"])],
    dependencies: [
        .package(url: "https://github.com/swift-atoms/swift-cardinal.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-trigonometry.git", branch: "main"),
        .package(url: "https://github.com/swift-atoms/swift-numeric.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "Bessel",
            dependencies: [
                .product(name: "Cardinal", package: "swift-cardinal"),
                .product(name: "Trigonometry", package: "swift-trigonometry"),
            ]
        ),
        .testTarget(
            name: "Bessel Tests",
            dependencies: [
                .target(name: "Bessel"),
                .product(name: "Numeric", package: "swift-numeric"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    target.swiftSettings =
        (target.swiftSettings ?? []) + [
            .strictMemorySafety(),
            .enableUpcomingFeature("ExistentialAny"),
            .enableUpcomingFeature("InternalImportsByDefault"),
            .enableUpcomingFeature("MemberImportVisibility"),
            .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            .enableUpcomingFeature("InferIsolatedConformances"),
            .enableExperimentalFeature("Lifetimes"),
            .treatAllWarnings(as: .error),
        ]
}
