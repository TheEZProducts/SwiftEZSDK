//
//  EZActorWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//


import Foundation

/// A tiny actor-backed box for a single value.
///
/// `EZActorWrapper` serializes access to a mutable value using actor isolation.
/// From outside the actor, calls to `get/set/update` require `await`.
///
/// ### Example
/// ```swift
/// let box = EZActorWrapper(value: 0)
/// await box.update { $0 += 1 }
/// let v = await box.get() // 1
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZActorWrapper<Value>{
    private var value: Value

    /// Returns the current value.
    ///
    /// ### Example
    /// ```swift
    /// let box = EZActorWrapper(value: "hello")
    /// let s = await box.get()
    /// ```
    public func get() -> Value { value }

    /// Replaces the stored value.
    ///
    /// ### Example
    /// ```swift
    /// let box = EZActorWrapper(value: 0)
    /// await box.set(10)
    /// ```
    public func set(_ value: Value) { self.value = value }

    /// Runs `action` with inout access to the stored value and returns its result.
    ///
    /// Use this for atomic read/modify/write operations.
    ///
    /// ### Example
    /// ```swift
    /// let box = EZActorWrapper(value: 1)
    /// let old = await box.update { value in
    ///     defer { value += 1 }
    ///     return value
    /// }
    /// // old == 1, stored value == 2
    /// ```
    @discardableResult
    public func update<Result>(_ action: (inout Value) throws -> (Result)) rethrows -> Result {
        try action(&value)
    }

    /// Creates a wrapper with an initial value.
    public init(value: Value) {
        self.value = value
    }
}
