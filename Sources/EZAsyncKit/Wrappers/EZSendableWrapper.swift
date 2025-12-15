//
//  EZSendableWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

import EZHelpersKit

/// Small helpers to make values easier to pass across concurrency boundaries.
///
/// - `EZUnsafeSendableWrapper` is **@unchecked Sendable**: you are responsible for thread-safety.
/// - `EZSendableWrapper` is a `@propertyWrapper` that serializes access with `EZRecursiveMutex`
///   from `EZHelpersKit`.
///


/// A minimal **@unchecked Sendable** box.
///
/// This does **not** provide any synchronization. Use only when the wrapped value is already
/// safe to share (e.g. immutable value types) or when you enforce your own locking.
///
/// ### Example
/// ```swift
/// let box = EZUnsafeSendableWrapper([1, 2, 3])
/// // You are responsible for ensuring safe access to `box.value`.
/// ```
public struct EZUnsafeSendableWrapper<Value>: @unchecked Sendable {
    public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
}

/// Thread-safe `@propertyWrapper` that serializes `get / set / update` with `EZRecursiveMutex`.
///
/// `wrappedValue` provides convenient access, but for read-modify-write operations prefer `update(_:)`
/// to keep the whole mutation atomic. There are two overloads:
/// - a deprecated `(inout T) -> R` variant, and
/// - the recommended overload that takes `EZAccess<T>` and works well with noncopyable values.
///
/// ### Example
/// ```swift
/// final class Counter {
///     @EZSendableWrapper var value: Int = 0
///
///     func inc() {
///         $value.update { access in
///             access.value += 1
///         }
///     }
/// }
/// ```
@propertyWrapper
public final class EZSendableWrapper<T>: Sendable {
    nonisolated(unsafe)
    private let _value: EZRecursiveMutex<T>
    
    /// Projected value (`$property`) exposing the explicit `get / set / update` API.
    public var projectedValue: EZSendableWrapper<T> { self }
    
    /// Convenient access to the value.
    ///
    /// For compound mutations (read → modify → write), use `update(_:)` to avoid races:
    ///
    /// ```swift
    /// $value.update { $0 += 1 }
    /// ```
    public var wrappedValue: T {
        set(value){ set(value) }
        consuming get { update { $0.value } }
    }
    
    /// Returns the current value (synchronously, under the lock).
    @inline(__always)
    public func get() -> T where T: Copyable { _value.get() }
    
    /// Replaces the current value (synchronously, under the lock).
    @inline(__always)
    public func set(_ value: consuming T) { _value.set(value) }
    
    /// Runs `closure` while holding the lock, allowing atomic read/modify/write.
    ///
    /// Deprecated: prefer the overload that takes `EZAccess<T>` instead, especially for noncopyable values.
    ///
    /// ### Example
    /// ```swift
    /// let old = $value.update { current in
    ///     defer { current += 1 }
    ///     return current
    /// }
    /// ```
    @available(*, deprecated, message: "Use update(_ closure: (borrowing EZAccess<T>) throws -> R) instead")
    @inline(__always)
    @discardableResult
    public func update<R>(_ closure: (inout T) throws -> (R)) rethrows -> R where R: ~Copyable  {
        try update { try closure(&$0.value) }
    }
    
    /// Preferred `update` overload that exposes the underlying value via `EZAccess<T>`.
    ///
    /// This works well with noncopyable values and keeps the whole mutation atomic.
    ///
    /// ### Example
    /// ```swift
    /// let old = $value.update { access in
    ///     defer { access.value += 1 }
    ///     return access.value
    /// }
    /// ```
    @inline(__always)
    @discardableResult
    public func update<R>(_ closure: (borrowing EZAccess<T>) throws -> (R)) rethrows -> R where R: ~Copyable {
        try _value.withLock(closure)
    }
    
    /// Creates the wrapper with an initial value.
    public init(wrappedValue: consuming T) {
        _value = .init(wrappedValue)
    }
    
    @inline(__always)
    public convenience init(_ value: consuming T) {
        self.init(wrappedValue: value)
    }
}
