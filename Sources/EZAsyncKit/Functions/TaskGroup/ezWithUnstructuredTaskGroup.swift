//
//  ezWithUnstructuredTaskGroup.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

import Foundation

import EZHelpersKit

/// Awaits several unstructured `Task` values in parallel and returns their results as a tuple.
///
/// All tasks are awaited concurrently, and this helper also wires in cancellation: if the
/// surrounding task is cancelled, all child tasks are cancelled as well via `withTaskCancellationHandler`.
///
/// - Parameters:
///   - result: Use `.values` to make the intent explicit (kept for symmetry with other helpers).
///   - values: A variadic tuple of non-throwing tasks.
/// - Returns: A tuple containing the `.value` of each task, in the same order.
///
/// ### Example
/// ```swift
/// let t1 = Task { 1 }
/// let t2 = Task { 2 }
///
/// let (a, b) = await ezWithUnstructuredTaskGroup(t1, t2)
/// // a == 1, b == 2
/// ```
@discardableResult
public func ezWithUnstructuredTaskGroup<each T>(
    result: EZTaskGroupResultValuesType = .values,
    _ values: repeat Task<each T, Never>
) async -> (repeat each T) {
    await withTaskCancellationHandler(
        operation: { (repeat await (each values).value) },
        onCancel: { repeat (each values).cancel() }
    )
}

/// Builder-based variant that awaits several non-throwing tasks and returns their values.
///
/// Uses `@EZTaskGroupBuilder` to construct the tuple of tasks, then forwards to the
/// non-builder overload.
///
/// ### Example
/// ```swift
/// let (a, b): (Int, String) = await ezWithUnstructuredTaskGroup {
///     Task { 1 }
///     Task { "two" }
/// }
/// ```
@discardableResult
public func ezWithUnstructuredTaskGroup<each T>(
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, Never>)
) async -> (repeat each T) {
    await ezWithUnstructuredTaskGroup(result: result, repeat each values())
}

/// Awaits several possibly-throwing tasks and either returns all values or throws an aggregated error.
///
/// Internally this helper first collects a tuple of `Result` values using the `.results` overload
/// and then:
/// - if at least one task failed, throws `EZGroupError` with all per-task results;
/// - otherwise, returns a tuple of all unwrapped values.
///
/// - Parameters:
///   - result: Use `.values` to request the all-or-nothing result mode.
///   - values: A variadic tuple of tasks whose failure type may differ.
/// - Throws: `EZGroupError` containing one `Result` for each task.
/// - Returns: A tuple of unwrapped values, in the same order.
///
/// ### Example
/// ```swift
/// let t1 = Task { try await loadUser() }
/// let t2 = Task { try await loadPosts() }
///
/// let (user, posts) = try await ezWithUnstructuredTaskGroup(t1, t2)
/// ```
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultValuesType = .values,
    _ values: repeat Task<each T, each Err>
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T) {
    let values = await ezWithUnstructuredTaskGroup(result: .results, repeat each values)

    var err = false
    for result in repeat each values {
        if case .failure(_) = result {
            err = true
        }
    }

    if err {
        throw EZGroupError(results: (repeat (each values)))
    } else {
        return (repeat try! (each values).get())
    }
}

/// Builder-based throwing variant that returns plain values or throws an aggregated error.
///
/// Uses `@EZTaskGroupBuilder` to build the tuple of tasks, then delegates to the
/// throwing `.values` overload.
///
/// ### Example
/// ```swift
/// let (user, posts) = try await ezWithUnstructuredTaskGroup {
///     Task { try await loadUser() }
///     Task { try await loadPosts() }
/// }
/// ```
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, each Err>)
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T) {
    return try await ezWithUnstructuredTaskGroup(result: result, repeat each values())
}

// MARK: - Unstructured Results
/// Awaits several possibly-throwing tasks and returns one `Result` per task.
///
/// Each child task is awaited in parallel. The function itself does not throw; instead, the
/// outcome of each task is captured as `Result<Success, Failure>` in the returned tuple.
///
/// - Parameters:
///   - result: Use `.results` to make the intent explicit.
///   - values: A variadic tuple of tasks to await.
/// - Returns: A tuple of `Result` values, preserving the order of `values`.
///
/// ### Example
/// ```swift
/// let t1 = Task { try await loadUser() }
/// let t2 = Task { try await loadPosts() }
///
/// let (userResult, postsResult): (Result<User, Error>, Result<[Post], Error>) =
///     await ezWithUnstructuredTaskGroup(result: .results, t1, t2)
/// ```
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultResultsType,
    _ values: repeat Task<each T, each Err>
) async -> (repeat Result<each T, each Err>) {
    return await withTaskCancellationHandler(
        operation: { (repeat await (each values).result) },
        onCancel: { repeat (each values).cancel() }
    )
}

/// Builder-based variant that returns `Result` values for each task.
///
/// Uses `@EZTaskGroupBuilder` to construct the tuple of tasks, then forwards to the
/// non-builder `.results` overload.
///
/// ### Example
/// ```swift
/// let (userResult, postsResult) = await ezWithUnstructuredTaskGroup(result: .results) {
///     Task { try await loadUser() }
///     Task { try await loadPosts() }
/// }
/// ```
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultResultsType,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, each Err>)
) async -> (repeat Result<each T, each Err>) {
    await ezWithUnstructuredTaskGroup(result: result, repeat each values())
}

// MARK: - Unstructured Optionals
/// Awaits several possibly-throwing tasks and returns optional values for each one.
///
/// This is a convenience wrapper over the `.results` overload:
/// - `.success(value)` becomes `value`
/// - `.failure(error)` becomes `nil`
///
/// - Parameters:
///   - result: Use `.optionals` to make the intent explicit.
///   - values: A variadic tuple of tasks.
/// - Returns: A tuple of optional values in the same order.
///
/// ### Example
/// ```swift
/// let t1 = Task { try await loadUser() }
/// let t2 = Task { try await loadPosts() }
///
/// let (user, posts): (User?, [Post]?) =
///     await ezWithUnstructuredTaskGroup(result: .optionals, t1, t2)
/// ```
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultOptionalsType,
    _ values: repeat Task<each T, each Err>
) async -> (repeat Optional<each T>) {
    return await withTaskCancellationHandler(
        operation: { (repeat try? await (each values).value) },
        onCancel: { repeat (each values).cancel() }
    )
}

/// Builder-based variant that returns optional values for each task.
///
/// Uses `@EZTaskGroupBuilder` to construct the tasks, then forwards to the non-builder
/// `.optionals` overload.
///
/// ### Example
/// ```swift
/// let (user, posts): (User?, [Post]?) = await ezWithUnstructuredTaskGroup(result: .optionals) {
///     Task { try await loadUser() }
///     Task { try await loadPosts() }
/// }
/// ```
@_disfavoredOverload
@discardableResult
public func ezWithUnstructuredTaskGroup<each T, each Err>(
    result: EZTaskGroupResultOptionalsType,
    @EZTaskGroupBuilder _ values: () -> (repeat Task<each T, each Err>)
) async -> (repeat Optional<each T>) {
    await ezWithUnstructuredTaskGroup(result: result, repeat each values())
}

