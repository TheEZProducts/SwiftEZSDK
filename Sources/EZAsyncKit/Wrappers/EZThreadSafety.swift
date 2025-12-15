//
//  File.swift
//
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

import EZHelpersKit

protocol EZThreadSafetyIsolatedValueProtocol<Value>: Sendable {
    associatedtype Value
    
    @discardableResult
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func update<R: Sendable>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) async rethrows -> R where R: ~Copyable
    
    @discardableResult
    func update<R>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
actor ActorIsolatedValue<Value>: EZThreadSafetyIsolatedValueProtocol {
    private nonisolated(unsafe)
    let _value: EZRecursiveMutex<Value>
    
    @inline(__always)
    @discardableResult
    nonisolated
    func update<R: Sendable>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) async rethrows -> R where R: ~Copyable  {
        try await isolatedUpdate(closure)
    }
    
    @inline(__always)
    @discardableResult
    private func isolatedUpdate<R>(_ closure: (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable  {
        try _value.withLock(closure)
    }
    
    
    @inline(__always)
    @discardableResult
    nonisolated
    func update<R>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable {
        try nonisolatedUpdate(closure)
    }
    
    @inline(__always)
    @discardableResult
    nonisolated
    private func nonisolatedUpdate<R>(_ closure: (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable {
        try _value.withLock(closure)
    }
    
    init(value: consuming Value) {
        self._value = .init(value)
    }
}

extension EZSendableWrapper: EZThreadSafetyIsolatedValueProtocol { }

/// Thread-safe access to a mutable value via `get / set / update`.
///
/// `EZThreadSafety` supports two usage modes:
/// - **Sync mode** (non-`async` code): `$value.get()/set()/update()` are always synchronized via `EZRecursiveMutex`
///   (either directly inside `ActorIsolatedValue` on Swift Concurrency platforms, or via `EZSendableWrapper`
///   on older OS versions without `async/await`).
/// - **Async mode** (`async` code): `await $value.get()/set()/update()` are executed under actor isolation
///   (`ActorIsolatedValue`) and still use `EZRecursiveMutex` under the hood to safely coordinate with sync access.
///
/// In practice this means:
/// - If you stay purely in async mode, access is serialized by the actor.
/// - If you stay purely in sync mode, access is serialized by the mutex.
/// - In mixed mode (sync + async), both paths share the same underlying storage and mutex, so you avoid races.
///
/// Prefer the projected value (`$property`) + `await` in async code.
/// Direct `wrappedValue` access is marked `noasync` to discourage using it from async contexts.
///
/// ### Example: pure async (actor provides isolation)
/// ```swift
/// struct Metrics: Sendable {
///     @EZThreadSafety var count: Int = 0
///
///     func inc() async {
///         await $count.update { access in
///             access.value += 1
///         }
///     }
///
///     func value() async -> Int {
///         await $count.get()
///     }
/// }
/// ```
///
/// ### Example: mixed mode (sync + async)
/// ```swift
/// final class Store: @unchecked Sendable {
///     @EZThreadSafety var items: [Int] = []
///
///     func addAsync(_ x: Int) async {
///         await $items.update { access in
///             access.value.append(x)
///         }
///     }
///
///     func countSync() -> Int {
///         $items.get().count
///     }
/// }
/// ```
@propertyWrapper
public struct EZThreadSafety<Value: Sendable>: Sendable {
    private let value: (any EZThreadSafetyIsolatedValueProtocol<Value>)
    
    /// Synchronous access to the wrapped value.
    ///
    /// This property is `noasync`: in async code, use `await $property.get()` / `await $property.set(_:)`.
    @available(*, noasync, message: "use let value = await $property.get() or await $property.set(value)")
    public var wrappedValue: Value {
        set(value) {
            self.value.update { $0.value = value }
        }
        get {
            return value.update { $0.value }
        }
    }
    
    /// Projected value (`$property`) that exposes the sync/async `get / set / update` APIs.
    public var projectedValue: Self { self }
    
    /// Atomically updates the stored value and returns a result (async).
    ///
    /// Deprecated: prefer the overload that takes `EZAccess<Value>` instead, especially for noncopyable values.
    ///
    /// ### Example
    /// ```swift
    /// let result = try await $value.update { current in
    ///     defer { current += 1 }
    ///     return current
    /// }
    /// ```
    @available(*, deprecated, message: "Use update(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> R) async rethrows -> R instead")
    @discardableResult
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func update<R: Sendable>(_ closure: @Sendable (inout Value) throws -> (R)) async rethrows -> R {
        try await value.update { try closure(&$0.value) }
    }
    
    /// Preferred async `update` overload that exposes the underlying value via `EZAccess<Value>`.
    ///
    /// Works well with noncopyable (`~Copyable`) values and keeps the whole mutation atomic.
    ///
    /// ### Example
    /// ```swift
    /// let result = try await $value.update { access in
    ///     defer { access.value += 1 }
    ///     return access.value
    /// }
    /// ```
    @discardableResult
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func update<R: Sendable>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) async rethrows -> R where R: ~Copyable {
        try await value.update(closure)
    }
    
    /// Atomically updates the stored value and returns a result (sync).
    ///
    /// Deprecated: prefer the overload that takes `EZAccess<Value>` instead, especially for noncopyable values.
    ///
    /// Safe to call from any thread.
    @available(*, deprecated, message: "Use update(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> R) instead")
    @discardableResult
    @available(*, noasync, message: "use await $property.update")
    public func update<R>(_ closure: @Sendable (inout Value) throws -> (R)) rethrows -> R {
        try value.update { try closure(&$0.value) }
    }
    
    /// Preferred sync `update` overload that exposes the underlying value via `EZAccess<Value>`.
    ///
    /// Safe to call from any thread and supports noncopyable (`~Copyable`) values.
    ///
    /// ### Example
    /// ```swift
    /// let result = $value.update { access in
    ///     defer { access.value += 1 }
    ///     return access.value
    /// }
    /// ```
    @discardableResult
    @_disfavoredOverload
    @available(*, noasync, message: "use await $property.update")
    public func update<R>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable {
        try value.update(closure)
    }
    
    /// Sets the value (async).
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func set(_ value: Value) async {
        await update { $0.value = value }
    }
    
    /// Sets the value (sync).
    @available(*, noasync, message: "use await $property.set")
    public func set(_ value: Value) {
        update { $0.value = value }
    }
    
    /// Gets the current value (async).
    @discardableResult
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func get() async -> Value {
        await update { $0.value }
    }
    
    /// Gets the current value (sync).
    @discardableResult
    @available(*, noasync, message: "use await $property.get")
    public func get() -> Value {
        update { $0.value }
    }
    
    /// Creates a thread-safe wrapper around `wrappedValue`.
    public init(wrappedValue: Value){
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            self.value = ActorIsolatedValue(value: wrappedValue)
        } else {
            self.value = EZSendableWrapper(wrappedValue: wrappedValue)
        }
    }
    
    @inline(__always)
    public init(_ value: Value) {
        self.init(wrappedValue: value)
    }
}
