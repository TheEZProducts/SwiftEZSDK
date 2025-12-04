//
//  EZSendableWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

/// Small wrappers to make values easier to pass across concurrency boundaries.
///
/// - `EZUnsafeSendableWrapper` is **@unchecked Sendable**: you are responsible for thread-safety.
/// - `EZSendableWrapper` is a `@propertyWrapper` that serializes access with a `DispatchSemaphore`.
///
/// Prefer `EZSendableWrapper` when you need safe, mutable shared state with low ceremony.

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

/// Thread-safe `@propertyWrapper` that serializes `get / set / update` with a semaphore.
///
/// `wrappedValue` provides convenience access, but for read-modify-write operations prefer `update(_:)`
/// to keep the whole mutation atomic.
///
/// ### Example
/// ```swift
/// final class Counter {
///     @EZSendableWrapper var value: Int = 0
///
///     func inc() {
///         $value.update { $0 += 1 }
///     }
/// }
/// ```
@propertyWrapper
public final class EZSendableWrapper<T>: Sendable {
    private let semaphore = DispatchSemaphore(value: 1)
    
    nonisolated(unsafe)
    private var value: T
    
    /// Projected value (`$property`) exposing the explicit `get / set / update` API.
    public var projectedValue: EZSendableWrapper<T> { self }
    
    /// Convenient access to the value.
    ///
    /// For compound mutations (read → modify → write), use `update(_:)` to avoid races:
    ///
    /// ```swift
    /// $value.update { $0 += 1 }
    /// ```
    public var wrappedValue: T{
        set(value){ set(value) }
        get { get() }
    }
    
    /// Returns the current value (synchronously, under the lock).
    public func get() -> T { update { $0 } }
    
    /// Replaces the current value (synchronously, under the lock).
    public func set(_ value: T) { update { $0 = value } }
    
    /// Runs `closure` while holding the lock, allowing atomic read/modify/write.
    ///
    /// ### Example
    /// ```swift
    /// let old = $value.update { current in
    ///     defer { current += 1 }
    ///     return current
    /// }
    /// ```
    @discardableResult
    public func update<Value>(_ clusure: (inout T) throws -> (Value)) rethrows -> Value{
        semaphore.wait(); defer { semaphore.signal() }
        return try clusure(&value)
    }
    
    /// Creates the wrapper with an initial value.
    public init(wrappedValue: T){
        semaphore.wait(); defer { semaphore.signal() }
        self.value = wrappedValue
    }
}
