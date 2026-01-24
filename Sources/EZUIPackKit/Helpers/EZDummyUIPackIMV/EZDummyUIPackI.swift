//
//  EZDummyUIPackI.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//
#if canImport(UIKit) && !os(watchOS)
import Foundation

/// A dummy interactor implementation for packs that don't need custom interactor logic.
///
/// `EZDummyUIPackI` is a generic interactor that works with mediators that have:
/// - `InputI == Void` (no interactor actions)
/// - `ViewModel == Void` (no shared state)
///
/// This is useful for wrapper packs (like `EZUINavigationWrapperPack` and `EZUITabBarWrapperPack`)
/// where you just need to wrap existing view controllers without implementing a full IMV pack.
///
/// ### Example: Usage in wrapper pack
///
/// ```swift
/// public typealias MyWrapperPack = EZUIPack<
///     EZDummyUIPackI<EZDummyUIPackM>,
///     EZDummyUIPackM,
///     EZDummyUIPackV<EZDummyUIPackM>
/// >
/// ```
///
/// - Note: This interactor provides no functionality beyond basic pack integration.
///   For any custom logic, create your own interactor class.
final public class EZDummyUIPackI<
    Mediator: EZUIPackMediatorProtocol
>: EZUIPackI where
    Mediator.ContextI == EZUIPackMediatorContextI<Mediator>,
    Mediator.InputI == Void,
    Mediator.ViewModel == Void
{
    /// Access to the mediator (provides no functionality for dummy packs).
    public let access = Mediator.accessI
    
    /// Creates an empty context with no actions or view model.
    ///
    /// - Returns: A context with `Void` actions and view model.
    public func makeContext() -> Mediator.ContextI {
        .init(actions: (), viewModel: ())
    }
}
#endif
