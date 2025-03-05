// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EZSDK",
    products: [
        //MARK: - Stable
        .library(name: "All", targets: [EZKit.name]),
        .library(name: EZAssociatedKit.name, targets: [EZAssociatedKit.name]),
        .library(name: EZAsyncKit.name, targets: [EZAsyncKit.name]),
        .library(name: EZObservableKit.name, targets: [EZObservableKit.name]),
        .library(name: EZBuilderKit.name, targets: [EZBuilderKit.name]),
        .library(name: EZSwiftUIBridgeKit.name, targets: [EZSwiftUIBridgeKit.name]),
        .library(name: EZUIPackKit.name, targets: [EZUIPackKit.name]),
        //MARK: - Experimental
        .library(name: EZJsonStriderKit._name, targets: [EZJsonStriderKit.name]),
        .plugin(name: EZJsonKeysPlugin._name, targets: [EZJsonKeysPlugin.name])
    ],
    targets: [
        //MARK: - Stable
        //MARK: - EZKit
        .target(
            name: EZKit.name,
            dependencies: [
                .target(name: EZAssociatedKit.name, condition: EZAssociatedKit.condition),
                .target(name: EZAsyncKit.name, condition: EZAsyncKit.condition),
                .target(name: EZObservableKit.name, condition: EZObservableKit.condition),
                .target(name: EZBuilderKit.name, condition: EZBuilderKit.condition),
                .target(name: EZSwiftUIBridgeKit.name, condition: EZSwiftUIBridgeKit.condition),
                .target(name: EZUIPackKit.name, condition: EZUIPackKit.condition)
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
        
        //MARK: - EZAsyncKit
        .target(
            name: EZAsyncKit.name,
            dependencies: [
                .target(name: EZAssociatedKit.name, condition: EZAssociatedKit.condition)
            ]
        ),
        .testTarget(
            name: EZAsyncKit.testName,
            dependencies: [
                .target(name: EZAsyncKit.name)
            ]
        ),
        
        //MARK: - EZObservableKit
        .target(
            name: EZObservableKit.name,
            dependencies: [
                .target(name: EZAssociatedKit.name, condition: EZAssociatedKit.condition),
                .target(name: EZAsyncKit.name, condition: EZAsyncKit.condition)
            ]
        ),
        .testTarget(
            name: EZObservableKit.testName,
            dependencies: [
                .target(name: EZObservableKit.name),
                .target(name: EZAssociatedKit.name)
            ]
        ),
        
        //MARK: - EZBuilderKit
        .target(
            name: EZBuilderKit.name,
            dependencies: []
        ),
        
        //MARK: - EZSwiftUIBridgeKit
        .target(
            name: EZSwiftUIBridgeKit.name,
            dependencies: []
        ),
        
        //MARK: - EZUIPackKit
        .target(
            name: EZUIPackKit.name,
            dependencies: [
                .target(name: EZSwiftUIBridgeKit.name, condition: EZSwiftUIBridgeKit.condition)
            ]
        ),
        
        //MARK: - Experimental
        //MARK: - EZJsonStriderKit
        .target(
            name: EZJsonStriderKit.name,
            dependencies: []
        ),
//        .testTarget(
//            name: EZJsonStriderKit.testName,
//            dependencies: [
//                .target(name: EZJsonStriderKit.name)
//            ],
//            resources: [.process("Resources")],
//            plugins: [
//                .plugin(name: EZJsonKeysPlugin.name)
//            ]
//        ),
        
        //MARK: - EZJsonKeysGenerator
        .executableTarget(name: EZJsonKeysGenerator.name),
        
        //MARK: - EZJsonKeysPlugin
        .plugin(
            name: EZJsonKeysPlugin.name,
            capability: .buildTool(),
            dependencies: [
                .target(name: EZJsonKeysGenerator.name, condition: EZJsonKeysGenerator.condition)
            ]
        )
    ]
)

//MARK: - EZTargetrotocol
protocol EZTargetProtocol{
    static var name: String {get}
    static var _name: String {get}
    static var testName: String {get}
    static var condition: TargetDependencyCondition? {get}
}
extension EZTargetProtocol{
    static var name: String {"\(Self.self)"}
    static var _name: String {"_\(name)"}
    static var testName: String { name + "Test" }
    static var condition: TargetDependencyCondition? { nil }
}

//MARK: - Stable Targets
//MARK: EZKit
struct EZKit: EZTargetProtocol{}

//MARK: EZAssociatedKit
struct EZAssociatedKit: EZTargetProtocol{
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst, .macOS, .tvOS, .watchOS])}
}

//MARK: EZAsyncKit
struct EZAsyncKit: EZTargetProtocol{}

//MARK: EZObservableKit
struct EZObservableKit: EZTargetProtocol{}

struct EZBuilderKit: EZTargetProtocol {}

//MARK: EZUIPackKit
struct EZUIPackKit: EZTargetProtocol {
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst])}
}

struct EZSwiftUIBridgeKit: EZTargetProtocol {
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst, .macOS, .tvOS])}
}

    
//MARK: - Experimental Targets
//MARK: EZJsonStriderKit
struct EZJsonStriderKit: EZTargetProtocol{}

//MARK: EZJsonKeysPlugin
struct EZJsonKeysPlugin: EZTargetProtocol{}

//MARK: EZJsonKeysGenerator
struct EZJsonKeysGenerator: EZTargetProtocol{}
