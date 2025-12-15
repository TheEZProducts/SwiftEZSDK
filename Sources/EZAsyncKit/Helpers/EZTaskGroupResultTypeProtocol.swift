//
//  EZTaskGroupResultTypeProtocol.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

/// Marker protocol for task-group result mode types.
///
/// Concrete conforming types (`EZTaskGroupResultValuesType`, `EZTaskGroupResultResultsType`,
/// `EZTaskGroupResultOptionalsType`) are used as lightweight tags to configure helpers like
/// `ezWithTaskGroup` and `ezWithUnstructuredTaskGroup`.
public protocol EZTaskGroupResultTypeProtocol {}

/// Tag type for task-group helpers that should return plain values.
///
/// Use `.values` when you want a tuple of unwrapped values (and are okay with the
/// helper throwing or otherwise handling failures separately).
public struct EZTaskGroupResultValuesType: EZTaskGroupResultTypeProtocol{
    /// Convenience singleton used to select the "values" mode.
    public static var values: Self { .init() }
}

/// Tag type for task-group helpers that should return `Result` values.
///
/// Use `.results` when you want per-task `Result<Success, Failure>` values and do not
/// want the helper itself to throw.
public struct EZTaskGroupResultResultsType: EZTaskGroupResultTypeProtocol{
    /// Convenience singleton used to select the "results" mode.
    public static var results: Self { .init() }
}

/// Tag type for task-group helpers that should return optional values.
///
/// Use `.optionals` when you only care whether each task produced a value or not,
/// and don't need the actual error for failures.
public struct EZTaskGroupResultOptionalsType: EZTaskGroupResultTypeProtocol{
    /// Convenience singleton used to select the "optionals" mode.
    public static var optionals: Self { .init() }
}
