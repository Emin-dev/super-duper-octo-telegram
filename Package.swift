// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RentbutikDomain",
    products: [.library(name: "RentbutikDomain", targets: ["RentbutikDomain"])],
    targets: [
        .target(name: "RentbutikDomain", path: "Rentbutik/Domain"),
        .testTarget(name: "RentbutikDomainTests", dependencies: ["RentbutikDomain"], path: "Tests")
    ]
)
