//
//  EZSUIPackInteractorProtocol.swift
//  EZSUIPackKit
//
//  Created by Александр Сенин on 07.02.2026.
//

#if canImport(SwiftUI)
import Foundation

/// Protocol for interactors in the SwiftUI IMV architecture.
///
/// Extends `EZIMVPackInteractorProtocol` with SwiftUI-specific lifecycle hooks:
/// - `onAppear()` — called when the pack's view appears
/// - `onDisappear()` — called when the pack's view disappears
///
/// ### Example
/// ```swift
/// class ProfilePackI: EZSUIPackI {
///     let access = ProfilePackM.accessI
///
///     func makeInput() -> Mediator.InputI { self }
///
///     func start() {
///         loadProfile()
///     }
///
///     func onAppear() {
///         refreshProfile()
///     }
/// }
/// ```
///
/// - Note: Use `EZSUIPackI` as the base type for SwiftUI interactors.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public protocol EZSUIPackInteractorProtocol: EZIMVPackInteractorProtocol
    where Mediator: EZSUIPackMediatorProtocol,
          Access == EZIMVPackAccessI<Mediator, Mediator.AccessMapI>
{
    /// Called when the pack's SwiftUI view appears.
    func onAppear()

    /// Called when the pack's SwiftUI view disappears.
    func onDisappear()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackInteractorProtocol {
    /// Default implementation: no-op.
    public func onAppear() {}
    /// Default implementation: no-op.
    public func onDisappear() {}
}

/// The primary type for creating SwiftUI interactors in the IMV architecture.
///
/// `EZSUIPackI` is a type alias for `EZSUIPackInteractorProtocol`. Use it as the base type
/// for all SwiftUI interactor implementations.
///
/// ### Example
/// ```swift
/// class MyPackI: EZSUIPackI {
///     let access = MyPackM.accessI
///     func makeInput() -> Mediator.InputI { self }
/// }
/// ```
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZSUIPackI = EZSUIPackInteractorProtocol
#endif
