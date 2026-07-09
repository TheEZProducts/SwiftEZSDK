//
//  EZIMVPackViewProtocol.swift
//  EZIMVPackKit
//
//  Created by Александр Сенин on 15.02.2026.
//

import Foundation

/// The platform-agnostic base protocol for views in the IMV architecture.
///
/// Defines the core view contract shared by UIKit (`EZUIPackViewBaseProtocol`) and SwiftUI
/// (`EZSUIPackViewProtocol`) views:
/// - `Mediator` — the mediator type this view works with, derived from `Access`
/// - `access` — the view's access flavor to the mediator (`viewModel`/`inputI` are derived from it)
/// - `makeInput()` — provides the view's action interface to the mediator
///
/// ### Example
/// ```swift
/// class MyIOSV: EZUIPackV {
///     let access = MyPackM.accessV
///
///     func makeInput() -> Mediator.InputV { self }
/// }
/// ```
@MainActor
public protocol EZIMVPackViewProtocol {
    /// The mediator type this view works with.
    associatedtype Mediator: EZIMVPackMediatorProtocol

    /// The concrete access flavor this view uses to reach the mediator.
    associatedtype Access: EZIMVPackViewAccess where Access.Mediator == Mediator

    /// The view's access object to the mediator.
    var access: Access { get }

    /// Provides the view's action interface to the mediator.
    ///
    /// Default implementations are provided when `Mediator.InputV` is `Void` or `Self`.
    func makeInput() -> Mediator.InputV
}

extension EZIMVPackViewProtocol {
    /// Read/write access to the shared view model, derived from `access`.
    public var viewModel: Mediator.ViewModel {
        _read { yield access.viewModel }
        nonmutating _modify { yield &access.viewModel }
    }

    /// Read-only access to the interactor's action interface, derived from `access`.
    public var inputI: Mediator.InputI {
        _read { yield access.inputI }
    }
}

extension EZIMVPackViewProtocol where Mediator.InputV == Void {
    /// Default implementation when `InputV` is `Void`.
    public func makeInput() -> Mediator.InputV { () }
}

extension EZIMVPackViewProtocol where Mediator.InputV == Self {
    /// Default implementation that returns `self` when the view is the input.
    public func makeInput() -> Mediator.InputV { self }
}
