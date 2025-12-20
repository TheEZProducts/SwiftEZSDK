//
//  File.swift
//
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

/// Convenience helper to tie an observation token's lifetime to an arbitrary object.
///
/// This file is only compiled when both `EZAssociatedKit` and Objective-C runtime are available.
/// The implementation uses associated objects to retain the token's `anchorObject` on the provided
/// `object`.
#if canImport(EZAssociatedKit) && canImport(ObjectiveC)
import EZAssociatedKit

/// Anchoring helpers for observation tokens.
extension EZObserverTokenProtocol {
    /// Attaches this token to `object` using an associated object.
    ///
    /// The token itself is not stored directly. Instead, the token's `anchorObject` is retained on
    /// `object`, which keeps the underlying observation alive until `object` is deallocated.
    ///
    /// - Parameter object: Any object whose lifetime should control the subscription.
    /// - Returns: `self` for fluent chaining.
    ///
    /// ### Example
    /// ```swift
    /// final class Owner {}
    ///
    /// let owner = Owner()
    /// $value.add { _ in }
    ///     .snapToObject(owner)
    ///
    /// // When `owner` is released, the observer is removed.
    /// ```
    @discardableResult
    public func snapToObject(_ object: AnyObject) -> Self{
        EZAssociated(object).set(anchorObject, .random, .OBJC_ASSOCIATION_RETAIN)
        return self
    }
}
#endif
