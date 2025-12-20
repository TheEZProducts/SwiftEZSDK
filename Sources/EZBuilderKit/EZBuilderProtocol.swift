//
//  EZBuilderProtocol.swift
//  Example
//
//  Created by Александр Сенин on 09.05.2023.
//

import Foundation

public protocol EZBuilderProtocol<V> {
    associatedtype V
    var value: V { get set }
    
    init(_ value: V)
}
 
public struct EZBuilderScript<V> {
    public var action: (V) -> ()
    public init(action: @escaping (V) -> Void) {
        self.action = action
    }
}

extension EZBuilderProtocol {
    public static func callAsFunction(_ action: @escaping (Self) -> ()) -> EZBuilderScript<V> {
        .init { action(Self($0)) }
    }
}

