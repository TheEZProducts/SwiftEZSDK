//
//  EZGroupError.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//


import Foundation

/// Aggregated error for task-group style helpers.
///
/// `EZGroupError` is typically used by functions like `ezWithTaskGroup` and
/// `ezWithUnstructuredTaskGroup` when they run several operations in parallel and at least one
/// of them fails.
///
/// Instead of throwing the first error and losing information about the rest, these helpers
/// wrap all per-task `Result` values into a single `EZGroupError`, so you can inspect successes
/// and failures after the fact.
///
/// The generic `T` is usually a tuple of `Result<Success, Failure>` values.
public struct EZGroupError<T: Sendable>: Error {
    /// The aggregated per-task results captured by the group helper.
    ///
    /// In practice this is most often a tuple of `Result<Success, Failure>` values
    /// (one for each child operation).
    public let results: T
}
 
extension EZGroupError {
    /// Flattens the stored tuple of `Result` values into a homogeneous `[Result<Any, any Error>]` array.
    ///
    /// This is useful when you want to iterate over all results regardless of their concrete
    /// success or failure types.
    ///
    /// The method is available when `T` is a variadic tuple of `Result<Success, Failure>` values.
    public func getResults<each Value, each Err>() -> [Result<Any, any Error>] where T == (repeat Result<each Value, each Err>) {
        var array = [Result<Any, any Error>]()
        for result in repeat each results {
            switch result{
            case .success(let value):
                array.append(.success(value))
            case .failure(let error):
                array.append(.failure(error))
            }
        }
        return array
    }

    /// Collects only the errors from all stored `Result` values.
    ///
    /// Returns an array of the failure values for every `.failure` case in `results`.
    public func getErrors<each Value, each Err>() -> [any Error] where T == (repeat Result<each Value, each Err>) {
        return Array(group: (repeat (each results).ezGetError()))
    }

    /// Collects only the successful values from all stored `Result` values.
    ///
    /// Returns an array of the success values for every `.success` case in `results`.
    public func getValues<each Value, each Err>() -> [Any] where T == (repeat Result<each Value, each Err>) {
        var array = [Any]()
        for result in repeat each results {
            if case .success(let value) = result{
                array.append(value)
            }
        }
        return array
    }
}
