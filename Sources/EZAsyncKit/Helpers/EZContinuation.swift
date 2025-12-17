//
//  EZContinuation.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

import EZHelpersKit

/// Errors produced by the continuation helpers in this file.
///
/// - `wasDeinit`: a continuation wrapper was deallocated before being resumed.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public enum EZContinuationError: String, LocalizedError, Sendable {
    case wasDeinit = "Was deallocated"
    
    public var errorDescription: String? { "EZContinuationError: \(rawValue)" }
}

/// A minimal interface for "continuation-like" types.
///
/// Conforming types can be resumed with either a value (`resume(returning:)`) or an error
/// (`resume(throwing:)`).
///
/// This protocol is used to share convenience helpers between `CheckedContinuation`,
/// `UnsafeContinuation`, and the wrapper types in this file.
public protocol EZContinuationProtocol<T, E>: Sendable {
    associatedtype T
    associatedtype E: Error
    
    func resume(throwing error: E)
    func resume(returning value: sending T)
}

extension EZContinuationProtocol{
    /// Resumes using a `Result` whose failure type can differ.
    ///
    /// This overload is available when `E == any Error`.
    ///
    /// ### Example
    /// ```swift
    /// cont.resume(with: Result<Int, SomeError>.success(1))
    /// cont.resume(with: Result<Int, SomeError>.failure(SomeError()))
    /// ```
    public func resume<Er>(with result: sending Result<T, Er>) where E == any Error, Er : Error {
        switch result {
        case .success(let value):
            resume(returning: value)
        case .failure(let error):
            resume(throwing: error)
        }
    }
    
    /// Resumes using a `Result` with the protocol's error type.
    ///
    /// ### Example
    /// ```swift
    /// cont.resume(with: .success(value))
    /// cont.resume(with: .failure(error))
    /// ```
    public func resume(with result: sending Result<T, E>) {
        switch result {
        case .success(let value):
            resume(returning: value)
        case .failure(let error):
            resume(throwing: error)
        }
    }
    
    /// Convenience for continuations whose value type is `Void`.
    ///
    /// ### Example
    /// ```swift
    /// cont.resume() // equivalent to cont.resume(returning: ())
    /// ```
    public func resume() where T == () {
        resume(returning: ())
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension CheckedContinuation: EZContinuationProtocol {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension UnsafeContinuation: EZContinuationProtocol {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension EZActionContinuation {
    struct Storage: Sendable {
        var action: (@Sendable (Result<T, Error>) async -> Void)?
        var wasUsed: Bool = false
    }
}

/// A continuation that forwards `resume(...)` into a user-provided async closure.
///
/// This is useful when you want a continuation-like API, but you don't actually need to suspend
/// the current task. Instead, calling `resume(...)` schedules the stored action in a new `Task`.
///
/// You can choose between:
/// - **one-shot mode** (default `isReusable == false`): the first `resume(...)` call invokes the
///   action, subsequent calls are ignored; if the continuation is deallocated before the first
///   resume, the action is called once with `.failure(EZContinuationError.wasDeinit)`.
/// - **reusable mode** (`isReusable == true`): every `resume(...)` call invokes the action; if the
///   continuation is deallocated without ever being resumed, the action is called once with
///   `.failure(EZContinuationError.wasDeinit)`.
///
/// ### Example (one-shot)
/// ```swift
/// let cont = EZActionContinuation<Int> { result in
///     print("got:", result)
/// }
///
/// cont.resume(returning: 1)   // calls action(.success(1))
/// cont.resume(returning: 2)   // ignored
/// ```
///
/// ### Example (reusable)
/// ```swift
/// let cont = EZActionContinuation<Int>(isReusable: true) { result in
///     print("got:", result)
/// }
///
/// cont.resume(returning: 1)
/// cont.resume(returning: 2)
/// // both values are delivered to `action`
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class EZActionContinuation<T: Sendable>: Sendable, EZContinuationProtocol {
    let storage: EZMutex<Storage>
    let isReusable: Bool
    
    /// Creates an action-backed continuation.
    ///
    /// - Parameter isReusable: Whether the action may be invoked more than once.
    ///   Defaults to `false` (one-shot behavior).
    public init(isReusable: Bool = false, action: @escaping @Sendable (Result<T, Error>) async -> Void) {
        self.isReusable = isReusable
        self.storage = .init(.init(action: action))
    }
    
    /// Resumes the continuation by scheduling `action(result)`.
    ///
    /// In one-shot mode (`isReusable == false`), only the first call has any effect.
    /// In reusable mode (`isReusable == true`), every call schedules the action.
    public func resume(with result: Result<T, Error>) {
        storage.withLock {
            guard let action = $0.value.action else { return }
            Task{[action] in
                await action(result)
            }
            $0.value.wasUsed = true
            if !isReusable { $0.value.action = nil }
        }
    }
    
    /// Resumes by failing with `error`.
    public func resume(throwing error: Error) {
        resume(with: .failure(error))
    }
    
    /// Resumes by succeeding with `value`.
    public func resume(returning value: sending T) {
        resume(with: .success(value))
    }
    
    deinit {
        storage.withLock {
            guard
                let action = $0.value.action,
                !$0.value.wasUsed
            else { return }
            Task{[action] in await action(.failure(EZContinuationError.wasDeinit)) }
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension EZSafeContinuation {
    struct Storage: Sendable {
        var continuation: CheckedContinuation<T, Error>?
        var result: Result<T, Error>?
    }
}

/// A continuation wrapper that is safe to resume before or after the underlying continuation exists.
///
/// `EZSafeContinuation` stores either:
/// - the underlying `CheckedContinuation`, or
/// - the first `Result` it was resumed with.
///
/// This lets you:
/// - `resume(...)` early (before `set(continuation:)` was called), or
/// - `set(continuation:)` late (after the result is already known).
///
/// Only the first resume wins; later resumes are ignored.
/// If deallocated before being resumed, it fails with `EZContinuationError.wasDeinit`.
///
/// ### Example
/// ```swift
/// let safe = EZSafeContinuation<Int>()
/// safe.resume(returning: 1)
///
/// try await withCheckedThrowingContinuation { (cc: CheckedContinuation<Int, Error>) in
///     safe.set(continuation: cc) // will immediately resume with 1
/// }
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class EZSafeContinuation<T: Sendable>: Sendable, EZContinuationProtocol {
    private let storage: EZMutex<Storage>
    
    /// The stored result if the continuation has already been resumed, otherwise `nil`.
    public var result: Result<T, Error>? { storage.get().result }
    
    /// Creates a safe continuation wrapper.
    ///
    /// You can optionally provide the underlying continuation up front.
    public init(continuation: CheckedContinuation<T, Error>? = nil) {
        storage = .init(.init(continuation: continuation))
    }
    
    /// Sets (or replaces) the underlying `CheckedContinuation`.
    ///
    /// If a result was already produced, the continuation is resumed immediately.
    public func set(continuation: CheckedContinuation<T, Error>? = nil) {
        storage.withLock {
            if let value = $0.value.result {
                continuation?.resume(with: value)
            }else{
                $0.value.continuation = continuation
            }
        }
    }
    
    /// Resumes by failing with `error`.
    public func resume(throwing error: Error) {
        resume(with: .failure(error))
    }
    
    /// Resumes by succeeding with `value`.
    public func resume(returning value: sending T) {
        resume(with: .success(value))
    }
    
    /// Resumes with a `Result`.
    ///
    /// Only the first call wins; later calls are ignored.
    public func resume(with result: sending Result<T, Error>) {
        storage.withLock {[result] in
            guard $0.value.result == nil else { return }
            $0.value.result = result
            $0.value.continuation?.resume(with: result)
            $0.value.continuation = nil
        }
    }
     
    deinit { resume(with: .failure(EZContinuationError.wasDeinit)) }
}
