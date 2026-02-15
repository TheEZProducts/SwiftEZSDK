//
//  EZPackInteractorBaseProtocol.swift
//  EZUIPackBaseKit
//
//  Created by Александр Сенин on 15.02.2026.
//

import Foundation

/// The platform-agnostic base protocol for interactors in the IMV architecture.
///
/// Defines the core interactor contract shared by UIKit (`EZUIPackInteractorProtocol`)
/// and SwiftUI (`EZSUIPackInteractorProtocol`) interactors:
/// - `access` — controlled access to the mediator
/// - `makeInput()` — provides the interactor's action interface to the mediator
/// - `makeContext()` — optionally provides extra data for mediator initialization
/// - `didInitialize()` / `start()` — lifecycle hooks
///
/// ### Example
/// ```swift
/// class MyPackI: EZUIPackI {
///     let access = MyPackM.accessI
///
///     func makeInput() -> Mediator.InputI { self }
///
///     func start() {
///         // Called when the pack first appears
///     }
/// }
/// ```
@MainActor
public protocol EZPackInteractorBaseProtocol: AnyObject {
    /// The mediator type this interactor works with.
    associatedtype Mediator: EZPackMediatorBaseProtocol

    /// Optional context type for passing extra data to the mediator during initialization.
    ///
    /// Defaults to `Void`. Override to provide structured data:
    /// ```swift
    /// typealias Context = MyContext
    /// func makeContext() -> Context { .init(userId: userId) }
    /// ```
    associatedtype Context = Void

    /// The access object providing controlled access to the mediator.
    ///
    /// Initialize with the mediator's static factory:
    /// ```swift
    /// let access = MyPackM.accessI
    /// ```
    var access: Mediator.AccessI { get }

    /// Provides the interactor's action interface to the mediator.
    ///
    /// Default implementations are provided when `Mediator.InputI` is `Void` or `Self`.
    func makeInput() -> Mediator.InputI

    /// Provides optional context data for mediator initialization.
    ///
    /// Default implementation returns `()` when `Context == Void`.
    func makeContext() -> Context

    /// Called after the mediator is created and all components are connected.
    ///
    /// The mediator is accessible via `access` at this point.
    func didInitialize()

    /// Called when the pack first appears.
    ///
    /// Use this for initial data loading or setup that should happen once.
    func start()
}

// MARK: - Defaults

extension EZPackInteractorBaseProtocol {
    /// Default implementation: no-op.
    public func didInitialize() {}
    /// Default implementation: no-op.
    public func start() {}
}

extension EZPackInteractorBaseProtocol where Context == Void {
    /// Default implementation when `Context` is `Void`.
    public func makeContext() -> Context { () }
}

extension EZPackInteractorBaseProtocol where Mediator.InputI == Void {
    /// Default implementation when `InputI` is `Void`.
    public func makeInput() -> Mediator.InputI { () }
}

extension EZPackInteractorBaseProtocol where Mediator.InputI == Self {
    /// Default implementation that returns `self` when the interactor is the input.
    public func makeInput() -> Mediator.InputI { self }
}

// MARK: - Convenience

extension EZPackInteractorBaseProtocol {
    /// Shortcut to the mediator's view model for reading and writing shared state.
    ///
    /// Equivalent to `access.viewModel`.
    public var viewModel: Mediator.ViewModel {
        _read { yield self.access.viewModel }
        _modify { yield &self.access.viewModel }
    }

    /// Shortcut to the view's action interface.
    ///
    /// Equivalent to `access.inputV`.
    public var inputV: Mediator.InputV {
        _read { yield self.access.inputV }
    }
}
