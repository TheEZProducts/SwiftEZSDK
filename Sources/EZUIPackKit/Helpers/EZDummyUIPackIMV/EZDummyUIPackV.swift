//
//  EZDummyUIPackV.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

/// A dummy view implementation for packs that don't need custom view logic.
///
/// `EZDummyUIPackV` is a generic view that works with mediators that have:
/// - `InputV == Void` (no view actions)
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
/// - Note: This view provides no functionality beyond basic pack integration.
///   For any custom UI, create your own view class.
final public class EZDummyUIPackV<
    Mediator: EZUIPackMediatorProtocol
>: EZUIPackV where
    Mediator.ContextV == EZUIPackMediatorContextV<Mediator>,
    Mediator.InputV == Void
{
    /// Access to the mediator (provides no functionality for dummy packs).
    public let access = Mediator.accessV
    
    /// Creates an empty context with no actions.
    ///
    /// - Returns: A context with `Void` actions.
    public func makeContext() -> Mediator.ContextV { .init(actions: ()) }
}
#endif
