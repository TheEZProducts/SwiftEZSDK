//
//  EZUIPackViewBaseProtocol.swift
//  EZUIPackKit
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
public protocol EZUIPackViewBaseProtocol<Mediator>: EZIMVPackViewProtocol
    where Mediator: EZUIPackMediatorProtocol
{
    /// Re-anchored here so `Mediator` is inferred reliably from the typed
    /// `access` requirement below (cross-protocol inference is fragile).
    associatedtype Mediator: EZUIPackMediatorProtocol

    /// Access object providing controlled access to the mediator.
    ///
    /// Initialize with the mediator's static factory:
    /// ```swift
    /// let access = MyPackM.accessV
    /// ```
    var access: EZIMVPackAccessV<Mediator, Mediator.AccessMapV> { get }

    /// Called once when the view is first created, before it appears.
    func create()
}


extension EZUIPackViewBaseProtocol {
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

extension EZUIPackViewBaseProtocol {
    /// Access to the pack bridge for advanced operations.
    public var packBridge: EZUIPackBridge {
        _read { yield self.access.packBridge }
    }
}

extension EZUIPackViewBaseProtocol {
    /// Default implementation: no-op.
    ///
    /// Override this to perform initial view setup when the view is first created.
    public func create(){}
}
#endif
