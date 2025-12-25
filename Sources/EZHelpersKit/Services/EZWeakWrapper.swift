//
//  EZWeakWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 05.03.2025.
//

import Foundation

public protocol EZOptionalObject {
    associatedtype Wrapped: AnyObject
}
extension Optional: EZOptionalObject where Wrapped: AnyObject {}

@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZWeak() = #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_---")

@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZWeak<T>() = #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_---")

public typealias EZWeak<Value: EZOptionalObject> = EZWeakWrapper<Value.Wrapped>

@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZWeakConst() = #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_CI-")

@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZWeakConst<T>() = #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_CI-")

public typealias EZWeakConst<Value: EZOptionalObject> = EZWeakWrapper<Value.Wrapped>


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
    public weak var value: Value?
    
    public var wrappedValue: Value? {
        _read { yield value }
        _modify { yield &value }
    }
    
    /// Creates a wrapper holding `value` weakly.
    public init(wrappedValue: Value?) {
        self.value = wrappedValue
    }
    
    /// Creates a wrapper holding `value` weakly.
    public init(value: Value?) {
        self.value = value
    }
    
    public init(_ value: Value?) {
        self.value = value
    }
}

/// Conforms to `Sendable` when `Value` is `Sendable`.
extension EZWeakWrapper: Sendable where Value: Sendable {}
