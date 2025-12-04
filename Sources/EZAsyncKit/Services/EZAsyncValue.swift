//
//  AsyncValue.swift
//  Helpers
//
//  Created by Александр Сенин on 28.02.2025.
//

import Foundation

/// A single-assignment async value.
///
/// `EZAsyncValue` is a small helper that lets you create a value now and fulfill it later.
/// Callers `await get()` to receive the value (or error) once it becomes available.
///
/// The first completion wins: subsequent attempts to complete are ignored.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension EZAsyncValue {
    /// Internal storage that keeps the first completed value/error and resumes all waiters.
    actor Storage{
        private var value: Value?
        private var error: Error?
        
        private var continuations = [EZSafeContinuation<Value>]()
        
        func get() async throws -> Value {
            if let error = error {
                throw error
            }
            if let value = value {
                return value
            }
            return try await ezWithCheckedStoppableContinuation {
                continuations.append($0)
            }
        }
        
        func set(result: Result<Value, Error>){
            guard value == nil && error == nil else { return }
            switch result {
            case .success(let value):
                self.value = value
            case .failure(let error):
                self.error = error
            }
            continuations.forEach{ $0.resume(with: result) }
            continuations = []
        }
    }
}

/// A `Sendable` container that can be completed exactly once and awaited from many tasks.
///
/// Typical use cases:
/// - Bridge callback-based code into `async/await`.
/// - Expose a "promise-like" value across task boundaries.
///
/// ### Example: bridging a completion handler
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
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
final public class EZAsyncValue<Value: Sendable>: Sendable {
    private let storage = Storage()
    
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
        try await storage.get()
    }
    
    /// Creates an async value and passes a continuation to `action` so you can complete it.
    ///
    /// Complete the continuation exactly once (with either a value or an error).
    /// Additional completions are ignored.
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
    public init(action: (EZActionContinuation<Value>) -> ()) {
        let continuation = EZActionContinuation {[weak self] in
            await self?.storage.set(result: $0)
        }
    
        action(continuation)
    }
    
    /// Creates a pair: the async value and a continuation that can be stored and completed later.
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
    public static func makeValue() -> (value: EZAsyncValue, continuation: EZActionContinuation<Value>) {
        var continuation: EZActionContinuation<Value>!
        let value = Self { continuation = $0 }
        return (value, continuation)
    }
}

