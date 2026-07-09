//
//  EZIMVPackViewAccess.swift
//  EZIMVPackKit
//
//  Created by Александр Сенин on 07.07.2026.
//

import Foundation

/// The abstract contract every view-side access flavor fulfills.
///
/// Each rendering technology plugs its own concrete flavor (plain class, SwiftUI
/// `DynamicProperty`, …) into `EZIMVPackViewProtocol` through this protocol. The pack wires the
/// mediator into whatever flavor the view declared by calling `setMediator(_:)`.
///
/// - `viewModel` — read/write access to the shared view model
/// - `inputI` — read-only access to the interactor's action interface
/// - `setMediator(_:)` — the framework's flavor plug-point; re-binds the flavor's mediator container
@MainActor
public protocol EZIMVPackViewAccess<Mediator> {
    /// The mediator type this access works with.
    associatedtype Mediator: EZIMVPackMediatorProtocol

    /// Read/write access to the shared view model.
    var viewModel: Mediator.ViewModel { get nonmutating set }

    /// Read-only access to the interactor's action interface.
    var inputI: Mediator.InputI { get }

    /// Binds the mediator into the access. Called by the pack during setup.
    func setMediator(_ mediator: Mediator)
}
