//
//  EZTaskItem.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

import Foundation

/// A tiny wrapper that describes a unit of async work for task-group helpers.
///
/// `EZTaskItem` stores a `@Sendable` closure that can be started later, and is used by helpers
/// like `ezWithTaskGroup`, `ezWithUnstructuredTaskGroup`, `ezWithTaskGroupFirstCompleted`,
/// and `ezWithTaskGroupFirstSuccess`.
///
/// The generic parameters are:
/// - `R`: the result type produced by the task closure.
/// - `E`: the error type thrown by the task closure.
///
/// ### Example
/// ```swift
/// let item = EZTaskItem<Int, Error> {
///     try await loadNumber()
/// }
///
/// let value = try await ezWithTaskGroup(item)
/// ```
public struct EZTaskItem<R, E: Error>: Sendable {
    let task: @Sendable () async throws(E) -> R
    
    /// Creates a task item from an async closure.
    ///
    /// The closure is not started immediately; it will be executed when the corresponding
    /// task-group helper runs this item.
    public init(task: @Sendable @escaping () async throws(E) -> R) {
        self.task = task
    }
}
