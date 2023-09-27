//
//  EZBuildable.swift
//  Example
//
//  Created by Александр Сенин on 09.05.2023.
//

import Foundation

public protocol EZBuildableProtocol{
    init()
}

extension EZBuildableProtocol{
    @discardableResult
    public static func build<B: EZBuilderProtocol<Self>>(_ type: B.Type, _ closure: (B) -> ()) -> Self{
        Self.init().build(type, closure)
    }

    @discardableResult
    public func build<B: EZBuilderProtocol<Self>>(_ type: B.Type, _ closure: (B) -> ()) -> Self{
        closure(B.init(self))
        return self
    }
    
    @discardableResult
    public static func build(@RZAnyBuilder _ closure: () -> ([EZBuilderScript<Self>])) -> Self{
        Self().build(closure)
    }
    
    @discardableResult
    public func build(@RZAnyBuilder _ closure: () -> ([EZBuilderScript<Self>])) -> Self{
        closure().forEach{ $0.action(self) }
        return self
    }
}

extension EZBuildableProtocol{
    public var builder: EZBuilder<Self> { .init(self) }

    @discardableResult
    public static func build(_ closure: (EZBuilder<Self>) -> ()) -> Self{
        Self.init().build(closure)
    }

    @discardableResult
    public func build(_ closure: (EZBuilder<Self>) -> ()) -> Self{
        builder.use(closure)
        return self
    }
}

@resultBuilder public struct RZAnyBuilder{
    public static func buildBlock<T>(_ atrs: T...) -> [T] { atrs }
}
