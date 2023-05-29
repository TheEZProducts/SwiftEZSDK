//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

@propertyWrapper
public struct EZBinding<Value>: @unchecked Sendable{
    private var get: () -> Value
    private var set: (Value) -> Void
    
    public var wrappedValue: Value{
        nonmutating set(value){ set(value) }
        get{ get() }
    }
    mutating public func update(){ wrappedValue = wrappedValue }
    
    public init(get: @escaping () -> Value, set: @escaping (Value) -> Void){
        self.get = get
        self.set = set
    }
}
