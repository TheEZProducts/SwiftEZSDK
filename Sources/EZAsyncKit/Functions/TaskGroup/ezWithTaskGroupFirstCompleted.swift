//
//  ezWithSTaskGroupFirstCompleted.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

import Foundation

/// Runs several tasks in a `TaskGroup` and returns the first completed `Result`.
///
/// All tasks are started in parallel, and as soon as the first one finishes (either `.success`
/// or `.failure`), the group is cancelled and that `Result` is returned. If `ops` is empty,
/// `nil` is returned.
///
/// - Parameters:
///   - isolation: Optional actor isolation for the group (defaults to `#isolation`).
///   - result: Use `.results` to make the intent explicit.
///   - ops: An array of `EZTaskItem` operations to run in parallel.
/// - Returns: The first completed `Result`, or `nil` when there were no operations.
///
/// ### Example
/// ```swift
/// let tasks: [EZTaskItem<Int, Error>] = [
///     EZTaskItem { try await fastTask() },
///     EZTaskItem { try await slowTask() }
/// ]
///
/// let first = await ezWithTaskGroupFirstCompleted(result: .results, tasks)
/// ```
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    _ ops: [EZTaskItem<T, Error>]
) async -> Result<T, Error>? {
    guard !ops.isEmpty else { return nil }
    return await withTaskGroup(
        of: Result<T, Error>.self,
        returning: Result<T, Error>?.self,
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

        let first = await group.next()
        group.cancelAll()
        return first
    }
}

/// Convenience overload that takes a variadic list of `EZTaskItem`s.
///
/// Calls the array-based `ezWithTaskGroupFirstCompleted` under the hood.
///
/// ### Example
/// ```swift
/// let first = await ezWithTaskGroupFirstCompleted(
///     result: .results,
///     EZTaskItem { try await fastTask() },
///     EZTaskItem { try await slowTask() }
/// )
/// ```
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    _ ops: EZTaskItem<T, Error>...
) async -> Result<T, Error>? {
    await ezWithTaskGroupFirstCompleted(isolation: isolation, result: result, ops)
}

/// Builder-based variant that returns the first completed `Result`.
///
/// Uses `@EZTaskItemArrayBuilder` to describe the list of tasks, but otherwise behaves the
/// same as the array-based overload.
///
/// ### Example
/// ```swift
/// let first = await ezWithTaskGroupFirstCompleted(result: .results) {
///     EZTaskItem { try await fastTask() }
///     EZTaskItem { try await slowTask() }
/// }
/// ```
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    @EZTaskItemArrayBuilder _ ops: () -> [EZTaskItem<T, Error>]
) async -> Result<T, Error>? {
    await ezWithTaskGroupFirstCompleted(isolation: isolation, result: result, ops())
}


// MARK: - First completed value (throws on first failure)
/// Returns the value of the first completed task or throws if that task failed.
///
/// Internally this calls the `.results` overload, cancels remaining tasks, and then:
/// - if the first `Result` is `.success(value)`, returns `value`;
/// - if it is `.failure(error)`, throws `error`.
///
/// If `ops` is empty, `nil` is returned.
///
/// - Parameters:
///   - isolation: Optional actor isolation for the group (defaults to `#isolation`).
///   - result: Use `.values` to make the intent explicit.
///   - ops: An array of `EZTaskItem` operations to run in parallel.
/// - Returns: The value from the first completed task, or `nil` when `ops` is empty.
/// - Throws: The error from the first completed task if it failed.
///
/// ### Example
/// ```swift
/// let tasks: [EZTaskItem<Int, Error>] = [
///     EZTaskItem { try await fastTask() },
///     EZTaskItem { try await slowTask() }
/// ]
///
/// let value = try await ezWithTaskGroupFirstCompleted(tasks)
/// ```
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: [EZTaskItem<T, Error>]
) async throws -> T? {
    guard
        let first = await ezWithTaskGroupFirstCompleted(
            isolation: isolation,
            result: .results,
            ops
        ) else { return nil }
    return try first.get()
}

/// Convenience overload that takes a variadic list of `EZTaskItem`s and returns the first value.
///
/// Delegates to the array-based `.values` overload.
///
/// ### Example
/// ```swift
/// let value = try await ezWithTaskGroupFirstCompleted(
///     EZTaskItem { try await fastTask() },
///     EZTaskItem { try await slowTask() }
/// )
/// ```
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: EZTaskItem<T, Error>...
) async throws -> T? {
    try await ezWithTaskGroupFirstCompleted(isolation: isolation, result: result, ops)
}

/// Builder-based variant that returns the value of the first completed task.
///
/// Uses `@EZTaskItemArrayBuilder` to describe the tasks, then forwards to the array-based
/// `.values` overload.
///
/// ### Example
/// ```swift
/// let value = try await ezWithTaskGroupFirstCompleted {
///     EZTaskItem { try await fastTask() }
///     EZTaskItem { try await slowTask() }
/// }
/// ```
@discardableResult
public func ezWithTaskGroupFirstCompleted<T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskItemArrayBuilder _ ops: () -> [EZTaskItem<T, Error>]
) async throws -> T? {
    try await ezWithTaskGroupFirstCompleted(isolation: isolation, result: result, ops())
}

