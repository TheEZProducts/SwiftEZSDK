//
//  MainActor + ezUnsafeRun.swift
//  EZSDK
//
//  Created by Александр Сенин on 03.12.2025.
//

import Foundation

extension MainActor {
    nonisolated
    public static func ezUnsafeRun<Result>(
        @_implicitSelfCapture
        action: @MainActor @escaping @Sendable () -> (Result)
    ) -> Result {
        let action = unsafeBitCast(action, to: (() -> (Result)).self)
        return action()
    }
    
    nonisolated
    public static func ezUnsafeRun<Result>(
        @_implicitSelfCapture
        action: @MainActor @escaping @Sendable () throws -> (Result)
    ) throws -> Result {
        let action = unsafeBitCast(action, to: (() throws -> (Result)).self)
        return try action()
    }
}
