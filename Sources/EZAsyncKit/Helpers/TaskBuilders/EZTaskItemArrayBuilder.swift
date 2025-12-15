//
//  EZTaskItemArrayBuilder.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

import Foundation

/// A result builder for constructing arrays of `EZTaskItem`.
///
/// This builder is used by helpers like `ezWithTaskGroupFirstCompleted` and
/// `ezWithTaskGroupFirstSuccess` to describe a list of tasks in a small DSL:
///
/// ```swift
/// let value = try await ezWithTaskGroupFirstCompleted {
///     EZTaskItem { try await fastTask() }
///     EZTaskItem { try await slowTask() }
/// }
/// ```
///
/// The builder supports conditionals, optionals and loops via the standard
/// `buildArray`, `buildOptional`, `buildEither`, and `buildLimitedAvailability` hooks.
@resultBuilder
public enum EZTaskItemArrayBuilder {
    /// Collects a variadic list of `EZTaskItem` values into a single array.
    public static func buildBlock<T>(_ components: EZTaskItem<T, Error>...) -> [EZTaskItem<T, Error>] {
        components
    }

    /// Flattens nested arrays of `EZTaskItem` produced by loops inside the builder.
    public static func buildArray<T>(_ components: [[EZTaskItem<T, Error>]]) -> [EZTaskItem<T, Error>] {
        components.flatMap { $0 }
    }

    /// Handles optional branches inside the builder, falling back to an empty list.
    public static func buildOptional<T>(_ component: [EZTaskItem<T, Error>]?) -> [EZTaskItem<T, Error>] {
        component ?? []
    }

    /// Handles the `if` branch in conditional builder expressions.
    public static func buildEither<T>(first component: [EZTaskItem<T, Error>]) -> [EZTaskItem<T, Error>] {
        component
    }

    /// Handles the `else` branch in conditional builder expressions.
    public static func buildEither<T>(second component: [EZTaskItem<T, Error>]) -> [EZTaskItem<T, Error>] {
        component
    }

    /// Handles `#available` branches inside the builder.
    public static func buildLimitedAvailability<T>(_ component: [EZTaskItem<T, Error>]) -> [EZTaskItem<T, Error>] {
        component
    }
}
