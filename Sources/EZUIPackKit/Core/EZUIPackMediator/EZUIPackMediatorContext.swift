//
//  EZUIPackMediatorContext.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

import Foundation

#if canImport(UIKit) && !os(watchOS)

/// Context passed from the interactor to the mediator during initialization.
///
/// Contains the interactor's action interface (`actions`) and initial view model state.
/// The mediator uses this context to initialize its `inputI` and `viewModel` properties.
///
/// ### Example
/// ```swift
/// func makeContext() -> Mediator.ContextI {
///     .init(
///         actions: self,  // The interactor implements InputIProtocol protocol
///         viewModel: .init(profile: nil, isLoading: false)
///     )
/// }
/// ```
@MainActor
public struct EZUIPackMediatorContextI<M: EZUIPackMediatorProtocol> {
    /// The interactor's action interface.
    ///
    /// Typically the interactor itself (which implements `InputIProtocol`).
    public var actions: M.InputI
    
    /// The initial view model state.
    public var viewModel: M.ViewModel
    
    /// Creates a context from the interactor.
    ///
    /// - Parameters:
    ///   - actions: The interactor's action interface (typically `self`).
    ///   - viewModel: The initial view model state.
    public init(actions: M.InputI, viewModel: M.ViewModel) {
        self.actions = actions
        self.viewModel = viewModel
    }
}

/// Context passed from the view to the mediator during initialization.
///
/// Contains the view's action interface (`actions`). The mediator uses this context
/// to initialize its `inputV` property.
///
/// ### Example
/// ```swift
/// func makeContext() -> Mediator.ContextV {
///     .init(actions: self)  // The view implements InputVProtocol protocol
/// }
/// ```
@MainActor
public struct EZUIPackMediatorContextV<M: EZUIPackMediatorProtocol> {
    /// The view's action interface.
    ///
    /// Typically the view itself (which implements `InputVProtocol`).
    public var actions: M.InputV
    
    /// Creates a context from the view.
    ///
    /// - Parameter actions: The view's action interface (typically `self`).
    public init(actions: M.InputV) {
        self.actions = actions
    }
}

#endif
