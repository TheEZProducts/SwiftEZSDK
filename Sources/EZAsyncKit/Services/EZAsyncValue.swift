//
//  AsyncValue.swift
//  Helpers
//
//  Created by Александр Сенин on 28.02.2025.
//

import Foundation

/// A `Sendable` async value that can be awaited from many tasks and completed via a continuation.
///
/// Typical use cases:
/// - Bridge callback-based code into `async/await`.
/// - Expose a "promise-like" value across task boundaries.
/// - Optionally, keep pushing updated values into the same container (see `isAbleToUpdating`).
///
/// By default the first completion is the one that matters for all waiters: callers that are suspended
/// in `get()` are resumed once the first value/error arrives and subsequent `get()` calls simply
/// return the latest known result without suspending.
///
/// When `isAbleToUpdating == true`, the same continuation can be resumed multiple times:
/// - each new value/error overwrites the stored `result` inside `EZAsyncValue`;
/// - tasks that call `get()` after an update will see the latest result immediately.
///
/// ### Example: bridging a completion handler (one-shot)
/// ```swift
/// func fetchNumber(completion: @escaping (Result<Int, Error>) -> Void) {
///     // ...
/// }
///
/// let asyncValue = EZAsyncValue<Int> { continuation in
///     fetchNumber { result in
///         continuation.resume(with: result)
///     }
/// }
///
/// let number = try await asyncValue.get()
/// ```
///
/// ### Example: pushing updates
/// ```swift
/// let value = EZAsyncValue<Int>(isAbleToUpdating: true) { continuation in
///     continuation.resume(returning: 1)
///     continuation.resume(returning: 2) // overwrites stored result
/// }
///
/// // Later:
/// let latest = try await value.get() // 2
/// ```
///
/// ### Example: using `makeValue`
/// ```swift
/// let (value, continuation) = EZAsyncValue<Int>.makeValue()
///
/// Task {
///     continuation.resume(returning: 42)
/// }
///
/// let answer = try await value.get() // 42
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZAsyncValue<Value: Sendable>: Sendable {
    private var result: Result<Value, Error>? = nil
    private var continuations = [EZSafeContinuation<Value>]()
    
    /// Awaits the completed value.
    ///
    /// If the value is not completed yet, this suspends until it is.
    /// If it completed with an error, the error is thrown.
    ///
    /// ### Example
    /// ```swift
    /// let (value, continuation) = EZAsyncValue<Int>.makeValue()
    /// Task { continuation.resume(returning: 7) }
    /// print(try await value.get()) // 7
    /// ```
    public func get() async throws -> Value {
        try Task.checkCancellation()
        if let result { return try result.get() }
        return try await ezWithCheckedStoppableContinuation {
            continuations.append($0)
        }
    }
    
    private func set(result: Result<Value, Error>) {
        self.result = result
        continuations.forEach { $0.resume(with: result) }
        continuations = []
    }
    
    /// Creates an async value and passes a continuation to `action` so you can complete it.
    ///
    /// - Parameter isAbleToUpdating:
    ///   - `false` (default): the continuation behaves in a one-shot manner; the first completion
    ///     wakes all current waiters and stores the result, later completions are ignored.
    ///   - `true`: the continuation is reusable; each completion updates the stored result inside
    ///     `EZAsyncValue`, and future `get()` calls see the latest value/error immediately.
    ///
    /// ### Example
    /// ```swift
    /// let asyncValue = EZAsyncValue<String> { cont in
    ///     DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
    ///         cont.resume(returning: "ready")
    ///     }
    /// }
    ///
    /// let s = try await asyncValue.get() // "ready"
    /// ```
    public init(isAbleToUpdating: Bool = false, action: (EZActionContinuation<Value>) -> ()) {
        let continuation = EZActionContinuation(isReusable: isAbleToUpdating) {[weak self] in
            await self?.set(result: $0)
        }
    
        action(continuation)
    }
    
    /// Creates a pair: the async value and a continuation that can be stored and completed later.
    ///
    /// - Parameter isAbleToUpdating:
    ///   - `false` (default): the continuation is one-shot; only the first completion matters.
    ///   - `true`: the continuation is reusable and may be completed multiple times to update
    ///     the stored result in `EZAsyncValue`.
    ///
    /// ### Example
    /// ```swift
    /// let (value, continuation) = EZAsyncValue<Data>.makeValue()
    ///
    /// Task {
    ///     // Later...
    ///     continuation.resume(returning: Data([1, 2, 3]))
    /// }
    ///
    /// let data = try await value.get()
    /// ```
    public static func makeValue(isAbleToUpdating: Bool = false) -> (value: EZAsyncValue, continuation: EZActionContinuation<Value>) {
        var continuation: EZActionContinuation<Value>!
        let value = Self(isAbleToUpdating: isAbleToUpdating) { continuation = $0 }
        return (value, continuation)
    }
}
