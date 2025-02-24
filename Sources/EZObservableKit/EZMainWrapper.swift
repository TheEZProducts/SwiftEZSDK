//
//  EZMainWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 16.02.2025.
//

import Foundation

public struct EZMainWrapper{
    @discardableResult
    public static func run<Result>(action: @MainActor @Sendable @escaping () -> (Result)) -> Result{
        EZMainWrapperActor.actor.run(action: action)
    }
}

public protocol EZMainWrapperProtocol{
    @discardableResult
    static func run<Result>(action: @MainActor @Sendable @escaping () -> (Result)) -> Result
}

private struct EZMainWrapperActor: @preconcurrency EZMainWrapperProtocol{
    static var actor: EZMainWrapperProtocol.Type { self }
    
    @MainActor
    static func run<Result>(action: @MainActor @Sendable @escaping () -> (Result)) -> Result{
        action()
    }
}


public class EZSendableWrapper<Value>: @unchecked Sendable{
    public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
}
