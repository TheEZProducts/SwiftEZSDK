//
//  EZIMVPackInteractorAccess.swift
//  EZIMVPackKit
//
//  Created by Александр Сенин on 09.07.2026.
//

import Foundation

/// The abstract contract every interactor-side access fulfills.
///
/// The standard implementation (`EZIMVPackAccessI` in `EZUIPackHelpersKit`) plugs into
/// `EZIMVPackInteractorProtocol` through this protocol. The pack wires the mediator into the
/// access by calling `setMediator(_:)`.
///
/// - `viewModel` — read/write access to the shared view model
/// - `inputV` — read-only access to the view's action interface
/// - `setMediator(_:)` — the framework's plug-point; binds the mediator into the access
@MainActor
public protocol EZIMVPackInteractorAccess<Mediator> {
    /// The mediator type this access works with.
    associatedtype Mediator: EZIMVPackMediatorProtocol

    /// Read/write access to the shared view model.
    var viewModel: Mediator.ViewModel { get nonmutating set }

    /// Read-only access to the view's action interface.
    var inputV: Mediator.InputV { get }

    /// Binds the mediator into the access. Called by the pack during setup.
    func setMediator(_ mediator: Mediator)
}
