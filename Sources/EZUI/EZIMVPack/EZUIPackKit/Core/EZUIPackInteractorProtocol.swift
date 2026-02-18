//
//  EZUIPackInteractorProtocol.swift
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
/// - Provides input for mediator initialization via `makeInput()`
/// - Optionally provides additional context via `makeContext()`
/// - Responds to lifecycle events: `start()`, `didCreate()`, `willOpen()`, `didOpen()`, etc.
///
/// ### Example: Basic interactor implementation
/// ```swift
/// class ProfilePackI: EZUIPackI {
///     let access = ProfilePackM.accessI
///
///     func makeInput() -> Mediator.InputI { self }
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
public protocol EZUIPackInteractorProtocol: EZUIPackBaseInteractorProtocol,
    EZIMVPackInteractorProtocol, EZSharingProtocol
    where Mediator: EZUIPackMediatorProtocol
{
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
    /// Override this to provide shared data that child packs can access via their mediator's `ezParentShared` property.
    /// Returns `nil` by default.
    ///
/// ### Example
/// ```swift
/// extension EZSharedKeyChain<OnboardingPackI> {
///     var onboardingStatus: EZSharedKey<Self, OnboardingStatus> { .init(key: "OnboardingStatus") }
///     var onboardingActions: EZSharedKey<Self, OnboardingActions> { .init(key: "OnboardingActions") }
/// }
///
/// extension EZSharedKey {
///     static var onboardingChain: EZSharedKeyChain<OnboardingPackI> { .init() }
/// }
///
/// var shared: EZSharedStorage? {
///     .init([
///         .init(key: .onboardingChain.onboardingStatus, value: currentStatus),
///         .init(key: .onboardingChain.onboardingActions, value: actions)
///     ])
/// }
/// ```
    public var shared: EZSharedStorage? { nil }
}

extension EZUIPackInteractorProtocol {
    
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
