// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AsmaulHusna",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "AsmaulHusna", targets: ["AsmaulHusna"])
    ],
    targets: [
        .executableTarget(
            name: "AsmaulHusna",
            path: "Sources/AsmaulHusna"
        )
    ]
)
