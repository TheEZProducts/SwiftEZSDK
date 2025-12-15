//
//  ezWithTaskGroupFirstSuccess.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

import Foundation

/// Runs several tasks in a `TaskGroup` and returns the value of the first one that succeeds.
///
/// All tasks are started in parallel. As soon as a child finishes with `.success(value)`, the
/// group is cancelled and that `value` is returned. Failed tasks (`.failure`) are ignored as long
/// as at least one task eventually succeeds.
///
/// If `ops` is empty or all tasks fail, the function returns `nil`.
///
/// - Parameters:
///   - isolation: Optional actor isolation for the group (defaults to `#isolation`).
///   - ops: An array of `EZTaskItem` operations to run in parallel.
/// - Returns: The value produced by the first successful task, or `nil` if none succeeded.
///
/// ### Example
/// ```swift
/// let items: [EZTaskItem<Int, Error>] = [
///     EZTaskItem { try await fastNetworkCall() },
///     EZTaskItem { try await slowFallbackCall() }
/// ]
///
/// let firstSuccess = await ezWithTaskGroupFirstSuccess(items)
/// ```
@discardableResult
public func ezWithTaskGroupFirstSuccess<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ ops: [EZTaskItem<T, Error>]
) async -> T? {
    guard !ops.isEmpty else { return nil }

    return await withTaskGroup(
        of: Result<T, Error>.self,
        returning: T?.self,
        isolation: isolation
    ) { group in
        for op in ops {
            group.addTask {
                do {
                    return .success(try await op.task())
                } catch {
                    return .failure(error)
                }
            }
        }

        while let next = await group.next() {
            if case .success(let value) = next {
                group.cancelAll()
                return value
            }
        }

        return nil
    }
}

/// Builder-based variant that returns the value of the first successful task.
///
/// Uses `@EZTaskItemArrayBuilder` to describe the list of tasks, then forwards to the
/// array-based overload.
///
/// ### Example
/// ```swift
/// let value = await ezWithTaskGroupFirstSuccess {
///     EZTaskItem { try await fastNetworkCall() }
///     EZTaskItem { try await slowFallbackCall() }
/// }
/// ```
@discardableResult
public func ezWithTaskGroupFirstSuccess<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    @EZTaskItemArrayBuilder _ ops: () -> [EZTaskItem<T, Error>]
) async -> T? {
    await ezWithTaskGroupFirstSuccess(isolation: isolation, ops())
}

/// Convenience overload that takes a variadic list of `EZTaskItem`s and returns the first success.
///
/// Delegates to the array-based `ezWithTaskGroupFirstSuccess` overload.
///
/// ### Example
/// ```swift
/// let value = await ezWithTaskGroupFirstSuccess(
///     EZTaskItem { try await fastNetworkCall() },
///     EZTaskItem { try await slowFallbackCall() }
/// )
/// ```
@discardableResult
public func ezWithTaskGroupFirstSuccess<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ ops: EZTaskItem<T, Error>...
) async -> T? {
    await ezWithTaskGroupFirstSuccess(isolation: isolation, ops)
}


