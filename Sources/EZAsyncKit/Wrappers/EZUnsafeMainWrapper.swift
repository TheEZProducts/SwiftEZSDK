//
//  EZUnsafeMainWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

/// Deprecated helpers for running `@MainActor` closures synchronously.
///
/// These are thin wrappers around `MainActor.ezUnsafeRun` and exist only for backwards
/// compatibility. New code should call `MainActor.ezUnsafeRun` directly.
public struct EZUnsafeMainWrapper {
    /// Runs a non-throwing `@MainActor` closure synchronously by delegating to `MainActor.ezUnsafeRun`.
    ///
    /// Deprecated: call `MainActor.ezUnsafeRun` directly instead.
    @available(*, deprecated, message: "use MainActor.ezUnsafeRun instead")
    @discardableResult
    public static func run<Result>(
        @_implicitSelfCapture
        action: @MainActor @escaping @Sendable () -> (Result)
    ) -> Result {
        MainActor.ezUnsafeRun(action: action)
    }
    
    /// Runs a throwing `@MainActor` closure synchronously by delegating to `MainActor.ezUnsafeRun`.
    ///
    /// Deprecated: call `MainActor.ezUnsafeRun` directly instead.
    @available(*, deprecated, message: "use MainActor.ezUnsafeRun instead")
    @discardableResult
    public static func run<Result>(
        @_implicitSelfCapture
        action: @MainActor @escaping @Sendable () throws -> (Result)
    ) throws -> Result {
        try MainActor.ezUnsafeRun(action: action)
    }
}


