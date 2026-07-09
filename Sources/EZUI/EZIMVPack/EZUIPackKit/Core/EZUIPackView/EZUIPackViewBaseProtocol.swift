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
    where Mediator: EZUIPackMediatorProtocol,
          Access: EZUIPackViewAccessProtocol
{
    /// Called once when the view is first created, before it appears.
    func create()
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
