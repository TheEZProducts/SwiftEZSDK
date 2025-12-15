//
//  Untitled.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

import Foundation

import EZHelpersKit

// MARK: - Values
/// Runs several `EZTaskItem` operations in a structured `TaskGroup` and returns their values as a tuple.
///
/// This overload is for non-throwing tasks (`Failure == Never`) and returns the successful values directly.
/// The order of values in the result tuple matches the order of `ops`.
///
/// - Parameters:
///   - isolation: Optional actor isolation for the created task group (defaults to `#isolation`).
///   - result: Currently unused for this overload and defaults to `.values`.
///   - ops: A variadic list of `EZTaskItem` operations to run in parallel.
/// - Returns: A tuple of all values produced by `ops`, in the same order.
///
/// ### Example
/// ```swift
/// let (a, b): (Int, String) = await ezWithTaskGroup(
///     EZTaskItem { 1 },
///     EZTaskItem { "two" }
/// )
/// ```
public func ezWithTaskGroup<each T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: repeat (EZTaskItem<each T, Never>)
) async -> (repeat (each T)) {
    typealias Child = (Int, (any Sendable))
    typealias Storage = [Optional<any Sendable>]

    let raw: Storage = await withTaskGroup(
        of: Child.self,
        returning: Storage.self,
        isolation: isolation
    ) { group in
        var i = 0
        for op in repeat each ops {
            let idx = i; i += 1
            group.addTask { (idx, await op.task()) }
        }

        var storage = Storage(repeating: NSNull(), count: i)
        for await (idx, res) in group { storage[idx] = res }
        return storage
    }
    return raw.ezConvertToGroup(typs: repeat (each T).self)
}

/// Builder-based variant of `ezWithTaskGroup` that produces plain values.
///
/// Lets you describe the child tasks using `@EZTaskItemGroupBuilder` syntax.
/// The semantics are identical to the non-builder overload: run all tasks in a group and
/// return their values as a tuple in the same order.
///
/// ### Example
/// ```swift
/// let (a, b): (Int, String) = await ezWithTaskGroup {
///     EZTaskItem { 1 }
///     EZTaskItem { "two" }
/// }
/// ```
public func ezWithTaskGroup<each T: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat (EZTaskItem<each T, Never>))
) async -> (repeat each T) {
    await ezWithTaskGroup(isolation: isolation, result: result, repeat (each ops()))
}

/// Runs several possibly-throwing `EZTaskItem` operations and either returns all values or throws a group error.
///
/// Internally this executes the tasks using the `.results` mode, collects all `Result` values,
/// and then:
/// - if at least one child failed, throws `EZGroupError` containing the per-task results;
/// - otherwise, returns a tuple of all unwrapped values.
///
/// This is convenient when you want "all-or-nothing" semantics but still preserve individual errors.
///
/// - Parameters:
///   - isolation: Optional actor isolation for the created task group (defaults to `#isolation`).
///   - result: Defaults to `.values`; controls how the group is evaluated internally.
///   - ops: A variadic list of `EZTaskItem` operations to run in parallel.
/// - Throws: `EZGroupError` wrapping a tuple of `Result` values for each task.
/// - Returns: A tuple of all successful values, in the same order as `ops`.
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    _ ops: repeat EZTaskItem<each T, each Err>
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T) {
    let results: (repeat Result<each T, each Err>) = await ezWithTaskGroup(
        isolation: isolation,
        result: .results,
        repeat each ops
    )

    var hasFailure = false
    for r in repeat each results {
        if case .failure = r { hasFailure = true }
    }

    if hasFailure {
        throw EZGroupError(results: results)
    } else {
        return (repeat try! (each results).get())
    }
}

/// Builder-based variant of the throwing `ezWithTaskGroup` that returns plain values.
///
/// Uses `@EZTaskItemGroupBuilder` to describe a group of tasks and then applies the same
/// all-or-nothing semantics as the non-builder overload.
///
/// ### Example
/// ```swift
/// let (user, posts) = try await ezWithTaskGroup {
///     EZTaskItem { try await loadUser() }
///     EZTaskItem { try await loadPosts() }
/// }
/// ```
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultValuesType = .values,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, each Err>)
) async throws(EZGroupError<(repeat Result<each T, each Err>)>) -> (repeat each T) {
    try await ezWithTaskGroup(isolation: isolation, result: result, repeat (each ops()))
}

// MARK: - Results
/// Runs several possibly-throwing `EZTaskItem` operations and returns a `Result` for each one.
///
/// Unlike the `.values` overload, this function never throws on its own. Each child task's outcome
/// is captured as `Result<Success, Failure>` and returned in a tuple, preserving order.
///
/// - Parameters:
///   - isolation: Optional actor isolation for the created task group (defaults to `#isolation`).
///   - result: Use `.results` to make the intent explicit.
///   - ops: A variadic list of `EZTaskItem` operations to run in parallel.
/// - Returns: A tuple of `Result` values in the same order as `ops`.
///
/// ### Example
/// ```swift
/// let (userResult, postsResult): (Result<User, Error>, Result<[Post], Error>) =
///     await ezWithTaskGroup(
///         result: .results,
///         EZTaskItem { try await loadUser() },
///         EZTaskItem { try await loadPosts() }
///     )
/// ```
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    _ ops: repeat (EZTaskItem<each T, each Err>)
) async -> (repeat (Result<each T, each Err>)) {
    typealias Child = (Int, ((any Sendable)?, Error?))
    typealias Storage = [((any Sendable)?, Error?)]

    let raw: Storage = await withTaskGroup(
        of: Child.self,
        returning: Storage.self,
        isolation: isolation
    ) { group in
        var i = 0
        for op in repeat each ops {
            let idx = i; i += 1
            group.addTask {
                do {
                    return (idx, (try await op.task(), nil))
                } catch {
                    return (idx, (Int?.none, error))
                }
            }
        }

        var storage = Storage(repeating: (Int?.none, .init(_Concurrency.CancellationError())), count: i)
        for await (idx, res) in group { storage[idx] = res }
        return storage
    }

    let cortege = raw.ezConvertToGroup(typs: repeat (Optional<each T>, Optional<each Err>).self)
    return _ezWithTaskGroup_makeResults(cortege: repeat (each cortege))
}

/// Builder-based variant of `ezWithTaskGroup` that returns `Result` values.
///
/// Lets you describe the child tasks with `@EZTaskItemGroupBuilder` while still getting back
/// a tuple of `Result` values (one per task).
///
/// ### Example
/// ```swift
/// let (userResult, postsResult) = await ezWithTaskGroup(result: .results) {
///     EZTaskItem { try await loadUser() }
///     EZTaskItem { try await loadPosts() }
/// }
/// ```
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err: Error>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultResultsType,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, each Err>)
) async -> (repeat (Result<each T, each Err>)) {
    await ezWithTaskGroup(isolation: isolation, result: result, repeat (each ops()))
}

// MARK: - Optionals
/// Runs several possibly-throwing `EZTaskItem` operations and returns optionals for each value.
///
/// This is a convenience wrapper over the `.results` overload:
/// - `.success(value)` becomes `value`
/// - `.failure(error)` becomes `nil`
///
/// Useful when you don't care about the exact errors and just want to know which tasks produced values.
///
/// - Parameters:
///   - isolation: Optional actor isolation for the created task group (defaults to `#isolation`).
///   - result: Use `.optionals` to make the intent explicit.
///   - ops: A variadic list of `EZTaskItem` operations to run in parallel.
/// - Returns: A tuple of optional values in the same order as `ops`.
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err: Error>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultOptionalsType,
    _ ops: repeat EZTaskItem<each T, each Err>
) async -> (repeat Optional<each T>) {
    let results: (repeat Result<each T, each Err>) = await ezWithTaskGroup(
        isolation: isolation,
        result: .results,
        repeat each ops
    )

    return (repeat {
        switch (each results) {
        case .success(let v): return v
        case .failure: return nil
        }
    }())
}

/// Builder-based variant of `ezWithTaskGroup` that returns optional values.
///
/// Uses `@EZTaskItemGroupBuilder` to describe tasks and then applies the same semantics as the
/// non-builder `.optionals` overload: failures are mapped to `nil`.
///
/// ### Example
/// ```swift
/// let (user, posts): (User?, [Post]?) = await ezWithTaskGroup(result: .optionals) {
///     EZTaskItem { try await loadUser() }
///     EZTaskItem { try await loadPosts() }
/// }
/// ```
@_disfavoredOverload
public func ezWithTaskGroup<each T: Sendable, each Err>(
    isolation: isolated (any Actor)? = #isolation,
    result: EZTaskGroupResultOptionalsType,
    @EZTaskItemGroupBuilder _ ops: () -> (repeat EZTaskItem<each T, each Err>)
) async -> (repeat Optional<each T>) {
    await ezWithTaskGroup(isolation: isolation, result: result, repeat (each ops()))
}

// MARK: - Private helpers
private func _ezWithTaskGroup_makeResults<each T, each R: Error>(
    isolation: isolated (any Actor)? = #isolation,
    cortege: repeat (Optional<each T>, Optional<each R>)
) -> (repeat Result<each T, each R>) {
    return (repeat Result(cortege: (each cortege))!)
}
