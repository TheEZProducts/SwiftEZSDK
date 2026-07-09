// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let products: [Product] = [
    //MARK: - Stable
    .library(name: "All", targets: [EZKit.name]),
    .library(name: EZHelpersKit.name, targets: [EZHelpersKit.name]),
    .library(name: EZAssociatedKit.name, targets: [EZAssociatedKit.name]),
    .library(name: EZAsyncKit.name, targets: [EZAsyncKit.name]),
    .library(name: EZObservableKit.name, targets: [EZObservableKit.name]),
    .library(name: EZBuilderKit.name, targets: [EZBuilderKit.name]),
    .library(name: EZSwiftUIBridgeKit.name, targets: [EZSwiftUIBridgeKit.name]),
    .library(name: EZIMVPackKit.name, targets: [EZIMVPackKit.name]),
    .library(name: EZUIPackHelpersKit.name, targets: [EZUIPackHelpersKit.name]),
    .library(name: EZTransitionKit.name, targets: [EZTransitionKit.name]),
    .library(name: EZUIPackKit.name, targets: [EZUIPackKit.name]),
    .library(name: EZSUIPackKit.name, targets: [EZSUIPackKit.name]),
    //MARK: - Experimental
    .library(name: EZJsonStriderKit._name, targets: [EZJsonStriderKit.name]),
    .plugin(name: EZJsonKeysPlugin._name, targets: [EZJsonKeysPlugin.name])
]

let targets: [Target] = [
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
            .target(name: EZIMVPackKit.name, condition: EZIMVPackKit.condition),
            .target(name: EZUIPackHelpersKit.name, condition: EZUIPackHelpersKit.condition),
            .target(name: EZTransitionKit.name, condition: EZTransitionKit.condition),
            .target(name: EZUIPackKit.name, condition: EZUIPackKit.condition),
            .target(name: EZSUIPackKit.name, condition: EZSUIPackKit.condition)
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

    //MARK: - EZHelpersKit
    .target(
        name: EZHelpersKit.name,
        dependencies: [
            .target(name: EZAssociatedKit.name),
            .target(name: EZMacrosKit.name)
        ],
        swiftSettings: [.enableExperimentalFeature("Lifetimes")]
    ),
    .testTarget(
        name: EZHelpersKit.testName,
        dependencies: [
            .target(name: EZHelpersKit.name, condition: EZHelpersKit.condition)
        ]
    ),

    //MARK: - EZMacrosKit
    .target(
        name: EZMacrosKit.name,
        dependencies: [
            .target(name: EZMacros.name, condition: EZMacros.condition)
        ]
    ),

    //MARK: - EZAsyncKit
    .target(
        name: EZAsyncKit.name,
        dependencies: [
            .target(name: EZAssociatedKit.name, condition: EZAssociatedKit.condition),
            .target(name: EZHelpersKit.name, condition: EZHelpersKit.condition),
            .target(name: EZMacrosKit.name, condition: EZMacrosKit.condition)
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
            .target(name: EZAsyncKit.name, condition: EZAsyncKit.condition),
            .target(name: EZMacrosKit.name, condition: EZMacrosKit.condition)
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
        dependencies: [],
        path: EZSwiftUIBridgeKit.path
    ),

    //MARK: - EZIMVPackKit
    .target(
        name: EZIMVPackKit.name,
        dependencies: [],
        path: EZIMVPackKit.path
    ),

    //MARK: - EZUIPackHelpersKit
    .target(
        name: EZUIPackHelpersKit.name,
        dependencies: [
            .target(name: EZIMVPackKit.name, condition: EZIMVPackKit.condition)
        ],
        path: EZUIPackHelpersKit.path
    ),

    //MARK: - EZTransitionKit
    .target(
        name: EZTransitionKit.name,
        dependencies: [],
        path: EZTransitionKit.path
    ),

    //MARK: - EZUIPackKit
    .target(
        name: EZUIPackKit.name,
        dependencies: [
            .target(name: EZIMVPackKit.name, condition: EZIMVPackKit.condition),
            .target(name: EZUIPackHelpersKit.name, condition: EZUIPackHelpersKit.condition),
            .target(name: EZTransitionKit.name, condition: EZTransitionKit.condition),
            .target(name: EZSwiftUIBridgeKit.name, condition: EZSwiftUIBridgeKit.condition)
        ],
        path: EZUIPackKit.path
    ),

    //MARK: - EZSUIPackKit
    .target(
        name: EZSUIPackKit.name,
        dependencies: [
            .target(name: EZIMVPackKit.name, condition: EZIMVPackKit.condition),
            .target(name: EZUIPackHelpersKit.name, condition: EZUIPackHelpersKit.condition)
        ],
        path: EZSUIPackKit.path
    ),

    //MARK: - Macros
    .macro(
        name: EZMacros.name,
        dependencies: [],
        path: EZMacros.macrosPath
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

let package = Package(
    name: "EZSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_15),
        .tvOS(.v13),
        .watchOS(.v6),
        .macCatalyst(.v13),
        .visionOS(.v1)
    ],
    products: products,
    targets: targets
)

//MARK: - EZTargetrotocol
protocol EZTargetProtocol{
    static var name: String { get }
    static var _name: String { get }
    static var testName: String { get }
    static var condition: TargetDependencyCondition? { get }
    static var macrosPath: String { get }
    static var path: String? { get }
}
extension EZTargetProtocol{
    static var name: String {"\(Self.self)"}
    static var _name: String {"_\(name)"}
    static var testName: String { name + "Test" }
    static var condition: TargetDependencyCondition? { nil }
    static var macrosPath: String { "Macros/\(name)" }
    static var path: String? { nil }
}

//MARK: - Stable Targets
//MARK: EZKit
struct EZKit: EZTargetProtocol {}

//MARK: EZAssociatedKit
struct EZAssociatedKit: EZTargetProtocol {
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst, .visionOS, .macOS, .tvOS, .watchOS])}
}

//MARK: EZMacrosKit
struct EZMacrosKit: EZTargetProtocol {}

//MARK: EZAsyncKit
struct EZAsyncKit: EZTargetProtocol {}

//MARK: EZObservableKit
struct EZObservableKit: EZTargetProtocol {}

struct EZBuilderKit: EZTargetProtocol {}

struct EZHelpersKit: EZTargetProtocol {}

//MARK: EZIMVPackKit
struct EZIMVPackKit: EZTargetProtocol {
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst, .visionOS, .macOS, .tvOS, .watchOS])}
    static var path: String? { "Sources/EZUI/EZIMVPack/EZIMVPackKit" }
}

//MARK: EZUIPackHelpersKit
struct EZUIPackHelpersKit: EZTargetProtocol {
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst, .visionOS, .macOS, .tvOS, .watchOS])}
    static var path: String? { "Sources/EZUI/EZIMVPack/EZUIPackHelpersKit" }
}

//MARK: EZTransitionKit
struct EZTransitionKit: EZTargetProtocol {
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst, .visionOS, .tvOS])}
    static var path: String? { "Sources/EZUI/EZTransitionKit" }
}

//MARK: EZUIPackKit
struct EZUIPackKit: EZTargetProtocol {
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst, .visionOS, .tvOS])}
    static var path: String? { "Sources/EZUI/EZIMVPack/EZUIPackKit" }
}

//MARK: EZSUIPackKit
struct EZSUIPackKit: EZTargetProtocol {
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst, .visionOS, .macOS, .tvOS, .watchOS])}
    static var path: String? { "Sources/EZUI/EZIMVPack/EZSUIPackKit" }
}

struct EZSwiftUIBridgeKit: EZTargetProtocol {
    static var condition: TargetDependencyCondition? {.when(platforms: [.iOS, .macCatalyst, .visionOS, .macOS, .tvOS])}
    static var path: String? { "Sources/EZUI/EZSwiftUIBridgeKit" }
}

//MARK: - Macros
struct EZMacros: EZTargetProtocol {}

//MARK: - Experimental Targets
//MARK: EZJsonStriderKit
struct EZJsonStriderKit: EZTargetProtocol{}

//MARK: EZJsonKeysPlugin
struct EZJsonKeysPlugin: EZTargetProtocol{}

//MARK: EZJsonKeysGenerator
struct EZJsonKeysGenerator: EZTargetProtocol{}
