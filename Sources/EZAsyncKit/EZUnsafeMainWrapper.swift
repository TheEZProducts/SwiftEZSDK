//
//  EZUnsafeMainWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

public struct EZUnsafeMainWrapper {
    @discardableResult
    public static func run<Result>(action: @MainActor @Sendable @escaping () -> (Result)) -> Result {
        EZMainWrapperExecutor.executor.run(action: action)
    }
}

protocol EZMainWrapperProtocol{
    @discardableResult
    static func run<Result>(action: @MainActor @Sendable @escaping () -> (Result)) -> Result
}

struct EZMainWrapperExecutor: @preconcurrency EZMainWrapperProtocol{
    static var executor: EZMainWrapperProtocol.Type { self }
    
    @MainActor
    static func run<Result>(action: @MainActor @Sendable @escaping () -> (Result)) -> Result {
        action()
    }
}
