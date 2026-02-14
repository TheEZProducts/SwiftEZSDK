//
//  EZDummyUIPackM.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

/// A dummy mediator implementation for packs that don't need custom mediator logic.
///
/// `EZDummyUIPackM` is a mediator with no state (`ViewModel == Void`) and no action interfaces
/// (`InputI == Void`, `InputV == Void`). It provides the minimal infrastructure needed for
/// a pack to function.
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
/// - Note: This mediator provides no functionality beyond basic pack infrastructure.
///   For any shared state or communication, create your own mediator class.
final public class EZDummyUIPackM: EZUIPackMediator, EZUIPackMediatorProtocol {
    /// Creates a dummy mediator with empty inputs.
    ///
    /// - Parameters:
    ///   - inputI: Input from interactor (ignored, as `InputI` is `Void`).
    ///   - inputV: Input from view (ignored, as `InputV` is `Void`).
    public init(inputI: Void, inputV: Void) {}
}
#endif

