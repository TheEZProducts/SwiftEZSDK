//
//  performAsyncOperation.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

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
