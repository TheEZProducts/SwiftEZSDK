//
//  EZIMVPackMediatorProtocol.swift
//  EZIMVPackKit
//
//  Created by Александр Сенин on 15.02.2026.
//

import Foundation

// MARK: - Base Mediator Protocol

/// The platform-agnostic base protocol for mediators in the IMV (Interactor-Mediator-View) architecture.
///
/// `EZIMVPackMediatorProtocol` defines the fundamental contract that every mediator must fulfill:
/// - **ViewModel**: Shared state accessible to both interactor and view
/// - **InputI**: The interactor's action interface (typically a protocol the interactor conforms to)
/// - **InputV**: The view's action interface (protocol or struct with closures)
/// - **Access maps**: Control which mediator properties are exposed to interactor and view
///
/// This protocol is extended by platform-specific mediator protocols:
/// - `EZUIPackMediatorProtocol` (UIKit)
/// - `EZSUIPackMediatorProtocol` (SwiftUI)
///
/// ### Example: Minimal mediator
/// ```swift
/// class MyPackM: EZUIPackM {
///     var viewModel: ViewModel
///     @MainActor struct ViewModel { var count = 0 }
///
///     weak let inputI: InputIProtocol?
///     @MainActor protocol InputIProtocol: AnyObject { func increment() }
///
///     weak let inputV: InputVProtocol?
///     @MainActor protocol InputVProtocol: AnyObject { func refresh() }
///
///     init(inputI: InputI, inputV: InputV) {
///         self.inputI = inputI
///         self.inputV = inputV
///         self.viewModel = .init()
///     }
/// }
/// ```
@MainActor
public protocol EZIMVPackMediatorProtocol: AnyObject {
    // MARK: - Required Objects

    /// Shared state accessible to both interactor and view.
    associatedtype ViewModel
    var viewModel: ViewModel { get set }

    /// The interactor's action interface type.
    ///
    /// Typically a protocol that the interactor conforms to. Use `Void` if no actions are needed.
    associatedtype InputI
    var inputI: InputI { get }

    /// The view's action interface type.
    ///
    /// Can be a protocol (for class-based views) or a struct with closures (for SwiftUI views).
    /// Use `Void` if no actions are needed.
    associatedtype InputV
    var inputV: InputV { get }

    // MARK: - Access

    /// The type that maps mediator key paths for interactor access.
    ///
    /// Use `()` (Void) for no custom mapping. Define a struct with key path properties
    /// to expose specific mediator properties via `@dynamicMemberLookup`.
    associatedtype AccessMapI
    static var accessMapI: AccessMapI { get }

    /// The type that maps mediator key paths for view access.
    ///
    /// Use `()` (Void) for no custom mapping. Define a struct with key path properties
    /// to expose specific mediator properties via `@dynamicMemberLookup`.
    associatedtype AccessMapV
    static var accessMapV: AccessMapV { get }

    /// Called after the mediator is created and all components are connected.
    ///
    /// Override to perform setup that requires access to interactor and view inputs.
    func didInitialize()
}


extension EZIMVPackMediatorProtocol {
    /// Default implementation: no-op.
    public func didInitialize() {}
}


extension EZIMVPackMediatorProtocol where InputI == Void {
    /// Default implementation when `InputI` is `Void`.
    public var inputI: InputI { () }
}


extension EZIMVPackMediatorProtocol where InputV == Void {
    /// Default implementation when `InputV` is `Void`.
    public var inputV: InputV { () }
}


extension EZIMVPackMediatorProtocol where AccessMapI == () {
    /// Default implementation when `AccessMapI` is `Void` (no custom mapping).
    public static var accessMapI: AccessMapI { () }
}


extension EZIMVPackMediatorProtocol where AccessMapV == () {
    /// Default implementation when `AccessMapV` is `Void` (no custom mapping).
    public static var accessMapV: AccessMapV { () }
}

// MARK: - Key helpers

extension EZIMVPackMediatorProtocol {
    /// Creates a read-only key path reference for use in access maps.
    ///
    /// ### Example
    /// ```swift
    /// static var accessMapI: AccessMapI {
    ///     .init(someValue: rKey(\.someValue))
    /// }
    /// ```
    public static func rKey<Value>(
        _ keyPath: KeyPath<Self, Value>
    ) -> KeyPath<Self, Value> { keyPath }

    /// Creates a read-write key path reference for use in access maps.
    ///
    /// ### Example
    /// ```swift
    /// static var accessMapV: AccessMapV {
    ///     .init(someValue: rwKey(\.someValue))
    /// }
    /// ```
    public static func rwKey<Value>(
        _ keyPath: ReferenceWritableKeyPath<Self, Value>
    ) -> ReferenceWritableKeyPath<Self, Value> { keyPath }
}
