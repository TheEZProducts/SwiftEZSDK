//
//  EZBuilder.swift
//  Example
//
//  Created by Александр Сенин on 09.05.2023.
//

import Foundation

@dynamicMemberLookup
open class EZBuilder<V: EZBuildableProtocol>: EZBuilderProtocol{
    open var value: V
    
    public required init(_ value: V){
        self.value = value
    }
}

extension EZBuilderProtocol{
    public subscript(dynamicMember value: String) -> Self { self }
    
    @discardableResult
    public func callAsFunction(_ action: (Self) -> ()) -> Self {
        use(action)
    }
    
    @discardableResult
    public func use<B: EZBuilderProtocol>(builder: B.Type = B.self, _ action: (B) -> ()) -> Self where B.V == V{
        action(.init(value))
        return self
    }
    
    @discardableResult
    public func use(_ action: (Self) -> ()) -> Self{
        use(builder: Self.self, action)
    }
    
    @discardableResult
    public func useValue(_ action: (V) -> ()) -> Self{
        action(value)
        return self
    }
}
