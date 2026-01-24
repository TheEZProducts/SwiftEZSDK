//
//  EZViewProtocol.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

/// Base protocol for views in the IMV architecture.
///
/// Provides access to the mediator and defines the core view lifecycle methods.
/// Views implement this protocol to participate in the IMV pattern.
///
/// ### Example: Basic view implementation
/// ```swift
/// class ProfileIOSV: EZUIPackV {
///     let access = ProfilePackM.accessV
///     
///     func makeContext() -> Mediator.ContextV {
///         .init(actions: self)
///     }
///     
///     func create() {
///         // Set up UI elements
///         setupSubviews()
///     }
/// }
///
/// extension ProfileIOSV: ProfilePackM.InputVProtocol {
///     func showError(message: String) {
///         // Display error
///     }
/// }
/// ```
@MainActor
public protocol EZViewProtocol<Mediator> {
    /// The type of mediator that manages communication and state for this view.
    associatedtype Mediator: EZUIPackMediatorProtocol
    
    /// Access object providing controlled access to the mediator.
    ///
    /// Use this to read/write the view model and access the interactor's action interface.
    var access: Mediator.AccessV { get }
    
    /// Creates a new view instance.
    ///
    /// Views must be initializable without parameters.
    init()
   
    /// Creates the context needed to initialize the mediator.
    ///
    /// This context contains the view's action interface (typically `self`).
    ///
    /// - Returns: A context containing actions.
    ///
    /// ### Example
    /// ```swift
    /// func makeContext() -> Mediator.ContextV {
    ///     .init(actions: self)  // The view implements InputVProtocol
    /// }
    /// ```
    func makeContext() -> Mediator.ContextV
    
    /// Called once when the view is first created, before it appears.
    ///
    /// Use this to set up UI elements, configure subviews, and perform initial setup.
    /// This is called before `willOpen()` and `animateOpen()`.
    ///
    /// ### Example
    /// ```swift
    /// func create() {
    ///     backgroundColor = .systemBackground
    ///     setupSubviews()
    ///     configureConstraints()
    /// }
    /// ```
    func create()
}


extension EZViewProtocol {
    /// Access to the pack bridge for advanced operations.
    ///
    /// Use this to access the pack or interactor if needed for special cases.
    public var packBridge: EZUIPackBridge {
        _read { yield access.packBridge }
    }
    
    /// Access to the mediator's view model for reading and writing state.
    ///
    /// The view model holds the shared state. Views typically read from this to update UI,
    /// and can write to trigger updates in other components.
    ///
    /// ### Example
    /// ```swift
    /// func updateUI() {
    ///     if viewModel.isLoading {
    ///         showLoadingIndicator()
    ///     } else {
    ///         hideLoadingIndicator()
    ///         displayProfile(viewModel.profile)
    ///     }
    /// }
    /// ```
    public var viewModel: Mediator.ViewModel {
        _read { yield access.viewModel }
        nonmutating _modify { yield &access.viewModel }
    }
    
    /// Access to the interactor's action interface.
    ///
    /// Use this to call methods defined in the mediator's `InputIProtocol` protocol,
    /// allowing the view to trigger actions in the interactor.
    ///
    /// ### Example
    /// ```swift
    /// @objc func didTapEditButton() {
    ///     inputI.editProfile()
    /// }
    /// ```
    public var inputI: Mediator.InputI {
        _read { yield access.inputI }
    }
}

extension EZViewProtocol {
    /// Default implementation: no-op.
    ///
    /// Override this to perform initial view setup when the view is first created.
    public func create(){}
}
#endif
