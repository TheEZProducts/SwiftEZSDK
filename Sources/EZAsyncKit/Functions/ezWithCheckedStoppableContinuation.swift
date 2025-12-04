//
//  ezWithCheckedStoppableContinuation.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

/// Bridges callback-based APIs into Swift Concurrency using a continuation that is safe to resume from
/// cancellation handlers.
///
/// This helper wraps `withCheckedThrowingContinuation` and wires Task cancellation to automatically
/// resume the continuation by throwing `CancellationError()`.
///
/// Keep the body *short* and make sure you resume the continuation exactly once.
/// The provided `EZSafeContinuation` is intended to guard against common race conditions where a
/// cancellation handler and a callback might try to resume around the same time.
///
/// - Parameters:
///   - isolation: Actor isolation for the underlying continuation (defaults to the current isolation).
///   - body: Register your callback(s) and resume the continuation when you have a value or error.
/// - Returns: The value you pass to `resume(returning:)`.
/// - Throws: Any error you pass to `resume(throwing:)`, or `CancellationError` if the task is cancelled.
///
/// ### Example: wrapping a completion handler
/// ```swift
/// let number: Int = try await ezWithCheckedStoppableContinuation { cont in
///     api.fetchNumber { result in
///         switch result {
///         case .success(let value):
///             cont.resume(returning: value)
///         case .failure(let error):
///             cont.resume(throwing: error)
///         }
///     }
/// }
/// ```
///
/// ### Example: cancellation
/// ```swift
/// do {
///     _ = try await ezWithCheckedStoppableContinuation { cont in
///         api.longRunningCall { result in
///             // If the task was cancelled first, the continuation will already be resumed
///             // with `CancellationError`.
///             cont.resume(with: result)
///         }
///     }
/// } catch is CancellationError {
///     // Task was cancelled.
/// }
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public func ezWithCheckedStoppableContinuation<Result: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ body: (EZSafeContinuation<Result>) -> Void
) async throws -> Result {
    let safeContinuation = EZSafeContinuation<Result>()
    return try await withTaskCancellationHandler(
        operation: {
            return try await withCheckedThrowingContinuation(isolation: isolation) { continuation in
                safeContinuation.set(continuation: continuation)
                body(safeContinuation)
            }
        },
        onCancel: {
            safeContinuation.resume(throwing: CancellationError())
        },
        isolation: isolation
    )
}
