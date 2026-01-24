//
//  EZUIPackI.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation
import UIKit

/// Base protocol for interactors in the IMV architecture.
///
/// Provides access to the pack and transition controller. Typically you should use
/// `EZUIPackInteractorProtocol` instead, which adds mediator access and lifecycle methods.
@MainActor
public protocol EZUIPackBaseInteractorProtocol: UIViewController, EZTransitionControlledProtocol {
    /// Custom initialization data type for the interactor.
    ///
    /// Defaults to `Void`. Override to provide custom initialization parameters.
    associatedtype CustomInitData = Void
    
    /// The pack that manages this interactor.
    ///
    /// Provides access to the pack and its components.
    var pack: (any EZUIPackProtocol) { get }
}

extension EZUIPackBaseInteractorProtocol {
    /// The transition controller for custom view controller transitions.
    ///
    /// Delegates to the pack's `transitionController` property.
    public var transitionController: (any EZTransitionControllerProtocol)? {
        _read { yield pack.transitionController }
        _modify { yield &pack.transitionController }
    }
}
 
/// Protocol for interactors in the IMV architecture pattern.
///
/// An interactor handles business logic and user actions. It:
/// - Manages the connection to the mediator via `access`
/// - Provides context for mediator initialization via `makeContext()`
/// - Responds to lifecycle events: `start()`, `didCreate()`, `willOpen()`, `didOpen()`, etc.
///
/// ### Example: Basic interactor implementation
/// ```swift
/// class ProfilePackI: EZUIPackI {
///     let access = ProfilePackM.accessI
///     
///     func makeContext() -> Mediator.ContextI {
///         .init(actions: self, viewModel: .init())
///     }
///     
///     func start() {
///         // Load initial data
///         loadProfile()
///     }
///     
///     func didOpen() {
///         // Refresh data when pack becomes visible
///         refreshProfile()
///     }
/// }
///
/// extension ProfilePackI: ProfilePackM.InputIProtocol {
///     func didTapEdit() {
///         // Handle user action
///     }
/// }
/// ```
///
/// - Note: Use `EZUIPackI` (which is `EZUIPackInteractor & EZUIPackInteractorProtocol`) as your base class
///   to get automatic UIKit lifecycle integration.
@MainActor
public protocol EZUIPackInteractorProtocol: EZUIPackBaseInteractorProtocol, EZSharingProtocol {
    /// The type of mediator that manages communication and state for this interactor.
    associatedtype Mediator: EZUIPackMediatorProtocol
    
    /// Access object providing controlled access to the mediator.
    ///
    /// Use this to read/write the view model and access the view's action interface.
    var access: Mediator.AccessI { get }
    
    /// Creates the context needed to initialize the mediator.
    ///
    /// This context contains the interactor's action interface (typically `self`) and
    /// the initial view model state.
    ///
    /// - Returns: A context containing actions and initial view model.
    ///
    /// ### Example
    /// ```swift
    /// func makeContext() -> Mediator.ContextI {
    ///     .init(
    ///         actions: self,  // The interactor implements InputIProtocol
    ///         viewModel: .init(profile: nil, isLoading: false)
    ///     )
    /// }
    /// ```
    func makeContext() -> Mediator.ContextI
    
    /// Called after the mediator is created and connected, but before `start()`.
    ///
    /// Use this to perform setup that requires mediator access.
    func didInitialize()
    
    /// Called once when the pack first appears, before `create()`.
    ///
    /// Use this to load initial data or start background operations.
    func start()
    
    /// Called after the view's `create()` method completes.
    ///
    /// Use this to perform actions that require the view to be fully created.
    func didCreate()
    
    /// Called when the pack is about to become visible, before animations start.
    ///
    /// Use this to prepare data or update state before the pack appears.
    func willOpen()
    
    /// Called after the pack has fully appeared and animations completed.
    ///
    /// Use this to start timers, refresh data, or perform actions that should happen
    /// when the pack is visible.
    func didOpen()
    
    /// Called after the view's layout has completed for the first time.
    ///
    /// Use this to perform layout-dependent operations.
    func didInstall()
    
    /// Called when the pack is about to disappear, before animations start.
    ///
    /// Use this to pause operations or save state.
    func willClose()
    
    /// Called after the pack has fully disappeared and animations completed.
    ///
    /// Use this to clean up resources or stop timers.
    func didClose()
}

extension EZUIPackInteractorProtocol {
    /// Shared storage for passing data to child packs.
    ///
    /// Override this to provide shared data that child packs can access via their mediator's `ezParentShered` property.
    /// Returns `nil` by default.
    ///
    /// ### Example
    /// ```swift
    /// var shared: EZSharedStorage? {
    ///     let storage = EZSharedStorage()
    ///     storage.set(key: .userID, value: currentUserID)
    ///     return storage
    /// }
    /// ```
    public var shared: EZSharedStorage? { nil }
}

extension EZUIPackInteractorProtocol {
    /// Access to the mediator's view model for reading and writing state.
    ///
    /// The view model holds the shared state between interactor and view.
    /// Changes to the view model can trigger view updates.
    ///
    /// ### Example
    /// ```swift
    /// func loadProfile() {
    ///     viewModel.isLoading = true
    ///     // ... load data
    ///     viewModel.profile = loadedProfile
    ///     viewModel.isLoading = false
    /// }
    /// ```
    public var viewModel: Mediator.ViewModel {
        _read { yield access.viewModel }
        _modify { yield &access.viewModel }
    }
    
    /// Access to the view's action interface.
    ///
    /// Use this to call methods defined in the mediator's `InputVProtocol` protocol,
    /// allowing the interactor to trigger actions in the view.
    ///
    /// ### Example
    /// ```swift
    /// func showError() {
    ///     inputV.showError(message: "Failed to load")
    /// }
    /// ```
    public var inputV: Mediator.InputV {
        _read { yield access.inputV }
    }
}

extension EZUIPackInteractorProtocol {
    /// Called after the mediator is created and connected, but before `start()`.
    ///
    /// Use this to perform setup that requires mediator access.
    public func didInitialize(){}
    
    /// Called once when the pack first appears, before `create()`.
    ///
    /// Use this to load initial data or start background operations.
    public func start(){}
    
    /// Called after the view's `create()` method completes.
    ///
    /// Use this to perform actions that require the view to be fully created.
    public func didCreate(){}
    
    /// Called when the pack is about to become visible, before animations start.
    ///
    /// Use this to prepare data or update state before the pack appears.
    public func willOpen(){}
    
    /// Called after the pack has fully appeared and animations completed.
    ///
    /// Use this to start timers, refresh data, or perform actions that should happen
    /// when the pack is visible.
    public func didOpen(){}
    
    /// Called after the view's layout has completed for the first time.
    ///
    /// Use this to perform layout-dependent operations.
    public func didInstall(){}
    
    /// Called when the pack is about to disappear, before animations start.
    ///
    /// Use this to pause operations or save state.
    public func willClose(){}
    
    /// Called after the pack has fully disappeared and animations completed.
    ///
    /// Use this to clean up resources or stop timers.
    public func didClose(){}
}

#endif
