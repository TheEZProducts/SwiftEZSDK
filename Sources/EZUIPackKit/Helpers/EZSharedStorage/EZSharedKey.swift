//
//  EZSharedKey.swift
//  EZSDK
//
//  Created by Александр Сенин on 23.02.2025.
//

import Foundation

public protocol EZSharedKeyChainProtocol{}
public struct EZSharedKeyChain<T>: EZSharedKeyChainProtocol { public init(){} }

public protocol EZSharedKeyProtocol: Hashable{
    var key: String { get }
}

extension EZSharedKeyProtocol{
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.key == rhs.key }
    public func hash(into hasher: inout Hasher) { key.hash(into: &hasher) }
}


public struct EZSharedKey<Chain: EZSharedKeyChainProtocol, Value>: EZSharedKeyProtocol{
    public var key: String { "\(Chain.self)" + keyString + "\(Value.self)" }
    private var keyString: String
    
    public init(chain: Chain.Type = Chain.self, type: Value.Type = Value.self, key: String) {
        self.keyString = key
    }
}
