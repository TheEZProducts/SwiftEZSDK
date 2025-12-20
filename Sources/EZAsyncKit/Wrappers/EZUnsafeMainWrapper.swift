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
    @discardableResult
    public static func run<Result>(
        @_implicitSelfCapture
        action: @MainActor @escaping @Sendable () -> (Result)
    ) -> Result {
        let action = unsafeBitCast(action, to: (() -> (Result)).self)
        return action()
    }
    
    /// Runs a throwing `@MainActor` closure synchronously by delegating to `MainActor.ezUnsafeRun`.
    ///
    /// Deprecated: call `MainActor.ezUnsafeRun` directly instead.
    @discardableResult
    public static func run<Result>(
        @_implicitSelfCapture
        action: @MainActor @escaping @Sendable () throws -> (Result)
    ) throws -> Result {
        let action = unsafeBitCast(action, to: (() throws -> (Result)).self)
        return try action()
    }
}


