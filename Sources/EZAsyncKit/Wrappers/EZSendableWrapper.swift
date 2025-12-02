//
//  EZSendableWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

public struct EZUnsafeSendableWrapper<Value>: @unchecked Sendable {
    public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
}

@propertyWrapper
public final class EZSendableWrapper<T>: Sendable {
    private let semaphore = DispatchSemaphore(value: 1)
    
    nonisolated(unsafe)
    private var value: T
    
    public var projectedValue: EZSendableWrapper<T> { self }
    
    public var wrappedValue: T{
        set(value){
            semaphore.wait(); defer { semaphore.signal() }
            self.value = value
        }
        get{
            semaphore.wait(); defer { semaphore.signal() }
            return value
        }
    }
    
    @discardableResult
    public func update<Value>(_ clusure: (inout T) throws -> (Value)) rethrows -> Value{
        semaphore.wait(); defer { semaphore.signal() }
        return try clusure(&value)
    }
    
    public init(wrappedValue: T){
        semaphore.wait(); defer { semaphore.signal() }
        self.value = wrappedValue
    }
}

