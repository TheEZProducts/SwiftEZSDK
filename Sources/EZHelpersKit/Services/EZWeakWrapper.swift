//
//  EZWeakWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 05.03.2025.
//

import Foundation

/// A small wrapper that stores an object weakly.
///
/// Useful when you want to keep a reference in a `Sendable` container without extending the lifetime
/// of the object.
///
/// Note: if the wrapped object is deallocated, `value` becomes `nil`.
///
/// ### Example
/// ```swift
/// final class Owner {}
/// let owner = Owner()
/// let weakOwner = EZWeakWrapper(value: owner)
///
/// print(weakOwner.value != nil) // true
/// // When `owner` deallocates, `weakOwner.value` becomes nil.
/// ```
public struct EZWeakWrapper<Value: AnyObject> {
    /// The weakly-held object (nil after deallocation).
    public private(set) weak var value: Value?
    
    /// Creates a wrapper holding `value` weakly.
    public init(value: Value?) {
        self.value = value
    }
}

/// Conforms to `Sendable` when `Value` is `Sendable`.
extension EZWeakWrapper: Sendable where Value: Sendable {}
