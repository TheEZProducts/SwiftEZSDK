// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "EZSDK",
    products: [
        .library(name: "All", targets: [EZKit.name]),
        .library(name: EZAssociatedKit.name, targets: [EZAssociatedKit.name])
    ],
    targets: [
        //MARK: - EZKit
        .target(
            name: EZKit.name,
            dependencies: [
                .target(name: EZAssociatedKit.name, condition: EZAssociatedKit.condition)
            ]
        ),
        //MARK: - EZAssociatedKit
        .target(
            name: EZAssociatedKit.name,
            dependencies: []
        ),
        .testTarget(
            name: EZAssociatedKit.testName,
            dependencies: [
                .target(name: EZAssociatedKit.name)
            ]
        )
    ]
)

//MARK: - EZTargetrotocol
protocol EZTargetProtocol{
    static var name: String {get}
    static var testName: String {get}
    static var condition: TargetDependencyCondition? {get}
}
extension EZTargetProtocol{
    static var name: String {"\(Self.self)"}
    static var testName: String { name + "Test" }
    static var condition: TargetDependencyCondition? { nil }
}

//MARK: - Targets

//MARK: EZKit
struct EZKit: EZTargetProtocol{}

//MARK: EZAssociatedKit
struct EZAssociatedKit: EZTargetProtocol{
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst, .macOS, .tvOS, .watchOS])}
}
