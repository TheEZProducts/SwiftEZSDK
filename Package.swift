// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EZSDK",
    products: [
        .library(name: "All", targets: [EZKit.name]),
        .library(name: EZAssociatedKit.name, targets: [EZAssociatedKit.name]),
        .library(name: EZThreadSafetyKit.name, targets: [EZThreadSafetyKit.name]),
        .library(name: EZChannelKit.name, targets: [EZChannelKit.name]),
        .library(name: EZObservableKit.name, targets: [EZObservableKit.name])
    ],
    targets: [
        //MARK: - EZKit
        .target(
            name: EZKit.name,
            dependencies: [
                .target(name: EZAssociatedKit.name, condition: EZAssociatedKit.condition),
                .target(name: EZThreadSafetyKit.name, condition: EZThreadSafetyKit.condition),
                .target(name: EZChannelKit.name, condition: EZChannelKit.condition),
                .target(name: EZObservableKit.name, condition: EZObservableKit.condition)
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
        ),
        
        //MARK: - EZThreadSafetyKit
        .target(
            name: EZThreadSafetyKit.name,
            dependencies: []
        ),
        .testTarget(
            name: EZThreadSafetyKit.testName,
            dependencies: [
                .target(name: EZThreadSafetyKit.name)
            ]
        ),
        
        //MARK: - EZChannelKit
        .target(
            name: EZChannelKit.name,
            dependencies: []
        ),
        .testTarget(
            name: EZChannelKit.testName,
            dependencies: [
                .target(name: EZChannelKit.name),
                .target(name: EZThreadSafetyKit.name)
            ]
        ),
        
        //MARK: - EZObservableKit
        .target(
            name: EZObservableKit.name,
            dependencies: [
                .target(name: EZAssociatedKit.name, condition: EZAssociatedKit.condition),
                .target(name: EZThreadSafetyKit.name, condition: EZThreadSafetyKit.condition)
            ]
        ),
        .testTarget(
            name: EZObservableKit.testName,
            dependencies: [
                .target(name: EZObservableKit.name),
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

//MARK: EZThreadSafetyKit
struct EZThreadSafetyKit: EZTargetProtocol{}

//MARK: EZChannelKit
struct EZChannelKit: EZTargetProtocol{}

//MARK: EZObservableKit
struct EZObservableKit: EZTargetProtocol{}
    
