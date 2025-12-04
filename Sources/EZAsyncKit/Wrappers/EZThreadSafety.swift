//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

protocol EZThreadSafetyIsolatedValueProtocol<Value>: Sendable{
    associatedtype Value
    
    @discardableResult
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func update<Result: Sendable>(_ closure: @Sendable (inout Value) throws -> (Result)) async rethrows -> Result
    
    @discardableResult
    func update<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
actor ActorIsolatedValue<Value>: EZThreadSafetyIsolatedValueProtocol{
    private let semaphore = DispatchSemaphore(value: 1)
    
    private nonisolated(unsafe) var value: Value
    
    @discardableResult
    nonisolated func update<Result: Sendable>(_ closure: @Sendable (inout Value) throws -> (Result)) async rethrows -> Result{
        try await isolatedUpdate(closure)
    }
    
    @discardableResult
    private func isolatedUpdate<Result: Sendable>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result{
        try updateAction(closure)
    }
    
    @discardableResult
    nonisolated func update<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result{
        try updateAction(closure)
    }
    
    @discardableResult
    private nonisolated func updateAction<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result{
        semaphore.wait(); defer { semaphore.signal() }
        return try closure(&value)
    }
    
    init(value: Value) {
        self.value = value
    }
}

final class SemaphoreIsolatedValue<Value>: EZThreadSafetyIsolatedValueProtocol{
    private let semaphore = DispatchSemaphore(value: 1)
    
    private nonisolated(unsafe) var value: Value
    
    @discardableResult
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func update<Result: Sendable>(_ closure: @Sendable (inout Value) throws -> (Result)) async rethrows -> Result{
        try updateAction(closure)
    }
    
    @discardableResult
    func update<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result{
        try updateAction(closure)
    }
    
    @discardableResult
    private func updateAction<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result{
        semaphore.wait(); defer { semaphore.signal() }
        return try closure(&value)
    }
    
    init(value: Value) {
        self.value = value
    }
}

/// Thread-safe access to a mutable value via `get / set / update`.
///
/// `EZThreadSafety` supports two usage modes:
/// - **Sync mode** (non-`async` code): `$value.get()/set()/update()` are protected by a `DispatchSemaphore`.
/// - **Async mode** (`async` code): `await $value.get()/set()/update()` additionally run inside actor isolation.
///
/// Implementation notes:
/// - Synchronization is always backed by a `DispatchSemaphore`.
/// - On platforms with Swift Concurrency (macOS 10.15+, iOS 13+, ...), async operations are executed on an
///   internal actor, so if you *only* use the async API, the semaphore is typically uncontended.
/// - The semaphore primarily exists to correctly synchronize **mixed** access (sync and async calls racing).
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
///         await $count.update { $0 += 1 }
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
///         await $items.update { $0.append(x) }
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
            self.value.update{ $0 = value }
        }
        get {
            return value.update{ $0 }
        }
    }
    
    /// Projected value (`$property`) that exposes the sync/async `get / set / update` APIs.
    public var projectedValue: Self { self }
    
    /// Atomically updates the stored value and returns a result.
    ///
    /// Prefer this overload in async code.
    @discardableResult
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func update<Result: Sendable>(_ closure: @Sendable (inout Value) throws -> (Result)) async rethrows -> Result{
        try await value.update(closure)
    }
    
    /// Atomically updates the stored value and returns a result (sync).
    ///
    /// Safe to call from any thread.
    @discardableResult
    @available(*, noasync, message: "use await $property.update")
    public func update<Result>(_ closure: @Sendable (inout Value) throws -> (Result)) rethrows -> Result{
        try value.update(closure)
    }
    
    /// Sets the value (async).
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func set(_ value: Value) async {
        await update{ $0 = value }
    }
    
    /// Sets the value (sync).
    @available(*, noasync, message: "use await $property.set")
    public func set(_ value: Value) {
        update{ $0 = value }
    }
    
    /// Gets the current value (async).
    @discardableResult
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func get() async -> Value{
        await update{ $0 }
    }
    
    /// Gets the current value (sync).
    @discardableResult
    @available(*, noasync, message: "use await $property.get")
    public func get() -> Value{
        update{ $0 }
    }
    
    /// Creates a thread-safe wrapper around `wrappedValue`.
    public init(wrappedValue: Value){
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            self.value = ActorIsolatedValue(value: wrappedValue)
        } else {
            self.value = SemaphoreIsolatedValue(value: wrappedValue)
        }
    }
}
