//
//  EZUnsafeMainWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

public struct EZUnsafeMainWrapper {
    @available(*, deprecated, message: "use MainActor.ezUnsafeRun instead")
    @discardableResult
    public static func run<Result>(
        @_implicitSelfCapture
        action: @MainActor @escaping @Sendable () -> (Result)
    ) -> Result {
        MainActor.ezUnsafeRun(action: action)
    }
    
    @available(*, deprecated, message: "use MainActor.ezUnsafeRun instead")
    @discardableResult
    public static func run<Result>(
        @_implicitSelfCapture
        action: @MainActor @escaping @Sendable () throws -> (Result)
    ) throws -> Result {
        try MainActor.ezUnsafeRun(action: action)
    }
}


