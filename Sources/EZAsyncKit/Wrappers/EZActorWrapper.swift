//
//  EZActorWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZActorWrapper<Value>{
    private var value: Value
    
    public func get() -> Value { value }
    public func set(_ value: Value) { self.value = value }
    
    @discardableResult
    public func update<Result>(_ action: (inout Value) throws -> (Result)) rethrows -> Result {
        try action(&value)
    }
    
    public init(value: Value) {
        self.value = value
    }
}
