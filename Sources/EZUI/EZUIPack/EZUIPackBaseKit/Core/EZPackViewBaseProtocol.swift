//
//  EZPackViewBaseProtocol.swift
//  EZUIPackBaseKit
//
//  Created by Александр Сенин on 15.02.2026.
//

import Foundation

/// The platform-agnostic base protocol for views in the IMV architecture.
///
/// Defines the core view contract shared by UIKit (`EZViewProtocol`) and SwiftUI
/// (`EZSUIPackViewProtocol`) views:
/// - `Mediator` — the mediator type this view works with
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
public protocol EZPackViewBaseProtocol {
    /// The mediator type this view works with.
    associatedtype Mediator: EZPackMediatorBaseProtocol

    /// Access object providing controlled access to the mediator.
    ///
    /// Initialize with the mediator's static factory:
    /// ```swift
    /// let access = MyPackM.accessV
    /// ```
    var access: EZPackMediatorAccessV<Mediator, Mediator.AccessMapV> { get }

    /// Provides the view's action interface to the mediator.
    ///
    /// Default implementations are provided when `Mediator.InputV` is `Void` or `Self`.
    func makeInput() -> Mediator.InputV
}

extension EZPackViewBaseProtocol where Mediator.InputV == Void {
    /// Default implementation when `InputV` is `Void`.
    public func makeInput() -> Mediator.InputV { () }
}

extension EZPackViewBaseProtocol where Mediator.InputV == Self {
    /// Default implementation that returns `self` when the view is the input.
    public func makeInput() -> Mediator.InputV { self }
}
