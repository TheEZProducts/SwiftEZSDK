//
//  EZSharedStorage.swift
//  EZSDK
//
//  Created by Александр Сенин on 23.02.2025.
//

import Foundation

@MainActor
public protocol EZSharingProtocol {
    var shared: EZSharedStorage? { get }
}

public struct EZSharedStorage{
    private var storage = [String: Any]()
    
    public subscript<C, T>(_ key: EZSharedKey<C, T>) -> T? {
        set(value){ storage[key.key] = value }
        get{ storage[key.key] as? T }
    }
    
    public init(){}
    public init(_ controls: [EZSharedContainer]){ append(controls: controls) }
    public init<C, T>(key: EZSharedKey<C, T>, value: T){ append(key: key, value: value) }
    
    public mutating func append<C, T>(key: EZSharedKey<C, T>, value: T){
        self[key] = value
    }
    
    public mutating func append(controls: [EZSharedContainer]){
        controls.forEach { storage[$0.key.key] = $0.value }
    }
    
    public static func +(lhs: Self, rhs: Self?) -> Self{
        var new = lhs
        new += rhs
        return new
    }
    
    public static func +=(lhs: inout Self, rhs: Self?){
        rhs?.storage.forEach{ lhs.storage[$0.key] = $0.value }
    }
}

public struct EZSharedContainer{
    private(set) var key: any EZSharedKeyProtocol
    private(set) var value: Any
    
    public init<C, T>(key: EZSharedKey<C, T>, value: T){
        self.key = key
        self.value = value
    }
}
