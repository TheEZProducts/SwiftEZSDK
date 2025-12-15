//
//  EZTaskGroupBuilder.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

import Foundation

/// A result builder for constructing tuples of `Task` values.
///
/// `EZTaskGroupBuilder` is used by helpers like `ezWithUnstructuredTaskGroup` to let you write
/// a small DSL for spawning several tasks in parallel:
///
/// ```swift
/// let (a, b): (Int, String) = await ezWithUnstructuredTaskGroup {
///     Task { 1 }
///     Task { "two" }
/// }
/// ```
///
/// The builder supports both non-throwing (`Task<Success, Never>`) and throwing
/// (`Task<Success, Failure>`) tasks via overloaded `buildBlock` methods.
@resultBuilder public struct EZTaskGroupBuilder {
    /// Collects a variadic tuple of non-throwing tasks into a single tuple.
    public static func buildBlock<each T>(
        _ components: repeat Task<each T, Never>
    ) -> (repeat Task<each T, Never>) {
        (repeat each components)
    }

    /// Collects a variadic tuple of possibly-throwing tasks into a single tuple.
    @_disfavoredOverload
    public static func buildBlock<each T, each Err>(
        _ components: repeat Task<each T, each Err>
    ) -> (repeat Task<each T, each Err>) {
        (repeat each components)
    }
}
