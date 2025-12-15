//
//  EZDeinitAnchor.swift
//  EZSDK
//
//  Created by Александр Сенин on 03.12.2025.
//

import Foundation

#if canImport(EZAssociatedKit)
import EZAssociatedKit
#endif


/// A tiny helper that runs a closure when it is deallocated.
///
/// `EZDeinitAnchor` is useful for attaching cleanup to an object's lifetime without subclassing.
/// The action is executed **at most once** (calling `performAction()` manually also consumes it).
///
/// ### Example
/// ```swift
/// var token: EZDeinitAnchor? = EZDeinitAnchor {
///     print("cleanup")
/// }
/// token = nil // prints "cleanup"
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class EZDeinitAnchor: Sendable {
    private let deinitAction: EZMutex<@Sendable () -> ()>
    
    /// Creates an anchor that will execute `deinitAction` when the anchor is deallocated.
    ///
    /// The action is stored in a thread-safe box so that it can be consumed safely.
    public init(deinitAction: @Sendable @escaping () -> ()) {
        self.deinitAction = .init(deinitAction)
    }
    
    /// Executes the action immediately (if it hasn't run yet) and disables further execution.
    ///
    /// Calling this is optional—`deinit` will call it automatically.
    public func performAction() {
        deinitAction.withLock {
            $0.value()
            $0.value = {}
        }
    }
    
    deinit { performAction() }
}

#if canImport(EZAssociatedKit) && canImport(ObjectiveC)
extension EZDeinitAnchor {
    /// Attaches this anchor to an Objective-C object using associated objects.
    ///
    /// This keeps the anchor alive as long as `object` is alive, so the action runs when `object` is released.
    ///
    /// ### Example
    /// ```swift
    /// final class Owner: NSObject {}
    /// let owner = Owner()
    /// EZDeinitAnchor { print("owner deinit") }
    ///     .ezSnapToObject(owner)
    /// // When `owner` deallocates, prints "owner deinit".
    /// ```
    @discardableResult
    public func ezSnapToObject(_ object: AnyObject) -> Self {
        EZAssociated(object).set(self, .random, .OBJC_ASSOCIATION_RETAIN)
        return self
    }
}
#endif
