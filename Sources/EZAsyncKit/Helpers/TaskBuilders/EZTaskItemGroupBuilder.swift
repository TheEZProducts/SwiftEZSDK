//
//  EZTaskItemGroupBuilder.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

import Foundation

/// A result builder for constructing tuples of `EZTaskItem`.
///
/// `EZTaskItemGroupBuilder` powers the builder-style overloads of `ezWithTaskGroup`,
/// letting you describe several tasks in a small DSL:
///
/// ```swift
/// let (a, b): (Int, String) = try await ezWithTaskGroup {
///     EZTaskItem { 1 }
///     EZTaskItem { "two" }
/// }
/// ```
///
/// The builder supports both non-throwing (`Failure == Never`) and throwing (`Failure == Error`)
/// task items via overloaded `buildBlock` methods.
@resultBuilder public struct EZTaskItemGroupBuilder {
    /// Collects a variadic tuple of non-throwing `EZTaskItem` values into a single tuple.
    public static func buildBlock<each T>(
        _ components: repeat EZTaskItem<each T, Never>
    ) -> (repeat EZTaskItem<each T, Never>) {
        (repeat each components)
    }

    /// Collects a variadic tuple of possibly-throwing `EZTaskItem` values into a single tuple.
    @_disfavoredOverload
    public static func buildBlock<each T, each Err>(
        _ components: repeat EZTaskItem<each T, each Err>
    ) -> (repeat EZTaskItem<each T, each Err>) {
        (repeat each components)
    }
}

