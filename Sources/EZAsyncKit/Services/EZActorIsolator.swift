//
//  EZActorIsolator.swift
//  EZSDK
//
//  Created by Александр Сенин on 15.03.2025.
//

import Foundation

/// A tiny box that serializes access to a value using a chosen actor's isolation.
///
/// `EZActorIsolator` does not create its own actor. Instead, you provide an `Actor` (defaults to the
/// current `#isolation`) and all `update(...)` calls execute under that actor's isolation.
///
/// Use `unsafeUpdate` only when you are 100% sure you already have the required isolation.
///
/// ### Example: isolate mutations to a dedicated actor
/// ```swift
/// actor Lock {}
/// let lock = Lock()
///
/// let box = EZActorIsolator(isolation: lock, value: 0)
/// let v = try await box.update { $0 += 1; return $0 }
/// print(v) // 1
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class EZActorIsolator<Value>: Sendable {
    private let isolation: any Actor
    
    nonisolated(unsafe)
    private var value: Value
    
    /// Creates an isolator bound to `isolation` with an initial `value`.
    ///
    /// If you omit `isolation`, it uses the current `#isolation` at the creation site.
    public init(isolation: any Actor = #isolation, value: Value) {
        self.isolation = isolation
        self.value = value
    }
    
    /// Updates the value under the configured actor's isolation and returns the closure's result.
    ///
    /// This is the preferred API in async code.
    ///
    /// ### Example
    /// ```swift
    /// let box = EZActorIsolator(value: [Int]())
    /// await box.update { $0.append(1) }
    /// let count = try await box.update { $0.count }
    /// ```
    @discardableResult
    public func update<R: Sendable>(_ action: @Sendable (inout Value) throws -> (R)) async rethrows -> R {
        try await update(isolation: isolation, action)
    }
    
    /// Callback-based variant of `update(...)`.
    ///
    /// Internally this starts a `Task` and calls `result` with the async outcome.
    /// Useful when you need to bridge into non-async code.
    ///
    /// ### Example
    /// ```swift
    /// box.update({ $0 += 1; return $0 }) { result in
    ///     print(result)
    /// }
    /// ```
    public func update<R: Sendable>(
        _ action: @Sendable @escaping (inout Value) throws -> (R),
        result: @Sendable @escaping (Result<R, Error>) -> () = {_ in}
    ) {
        Task {
            do{
                result(.success(try await update(isolation: isolation, action)))
            }catch {
                result(.failure(error))
            }
        }
    }
    
    /// Updates the value **without** enforcing actor isolation.
    ///
    /// Use this only if the caller already has the correct isolation (or otherwise provides its own
    /// synchronization). If used incorrectly, this can introduce data races.
    ///
    /// ### Example (only safe if already on the actor)
    /// ```swift
    /// // Imagine we're already running on `lock`'s executor.
    /// _ = try box.unsafeUpdate { $0 += 1 }
    /// ```
    @discardableResult
    public func unsafeUpdate<R: Sendable>(_ action: @Sendable (inout Value) throws -> (R)) rethrows -> R {
        try update(isolation: nil, action)
    }
    
    @discardableResult
    private func update<R: Sendable>(
        isolation: isolated (any Actor)?,
        _ action: (inout Value) throws -> (R)
    ) rethrows -> R {
        try action(&value)
    }
}
