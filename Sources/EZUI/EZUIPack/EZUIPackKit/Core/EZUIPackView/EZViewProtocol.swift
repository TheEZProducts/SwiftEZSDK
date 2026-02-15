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
///     func makeInput() -> Mediator.InputV { self }
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
public protocol EZViewProtocol<Mediator>: EZPackViewBaseProtocol
    where Mediator: EZUIPackMediatorProtocol
{
    /// Access object providing controlled access to the mediator.
    var access: Mediator.AccessV { get }

    /// Called once when the view is first created, before it appears.
    func create()
}


extension EZViewProtocol {
    /// Access to the mediator's view model for reading and writing state.
    public var viewModel: Mediator.ViewModel {
        _read { yield self.access.viewModel }
        nonmutating _modify { yield &self.access.viewModel }
    }

    /// Access to the interactor's action interface.
    public var inputI: Mediator.InputI {
        _read { yield self.access.inputI }
    }
}

extension EZViewProtocol {
    /// Access to the pack bridge for advanced operations.
    public var packBridge: EZUIPackBridge {
        _read { yield self.access.packBridge }
    }
}

extension EZViewProtocol {
    /// Default implementation: no-op.
    ///
    /// Override this to perform initial view setup when the view is first created.
    public func create(){}
}
#endif
