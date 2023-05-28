//
//  File.swift
//  
//
//  Created by Александр Сенин on 28.05.2023.
//

import Foundation

public struct EZAssociated{
    public enum SetKey {
        case random
        case hashable(AnyHashable)
        case pointer(UnsafeRawPointer)
    }
    
    private weak var object: AnyObject?
    
    public init(_ object: AnyObject){ self.object = object }
    
    @discardableResult
    public func set(_ value: Any?, _ key: SetKey, _ policy: objc_AssociationPolicy) -> SetKey? {
        guard let object = object else {return nil}
        let key = getKey(key)
        objc_setAssociatedObject(object, key, value, policy)
        return .pointer(key)
    }
    
    public func get<ReturnObject>(_ key: SetKey) -> ReturnObject?{
        return get(key) as? ReturnObject
    }
    
    public func get(_ key: SetKey) -> Any?{
        guard let object = object else {return nil}
        let key = getKey(key)
        return objc_getAssociatedObject(object, key)
    }
    
    @discardableResult
    public func setDeinitObserver(_ key: SetKey = .random, _ handler: @escaping () -> ()) -> SetKey?{
        let provider = DeinitProvider(handler)
        return set(provider, key, .OBJC_ASSOCIATION_RETAIN)
    }
    
    private func getKey(_ key: SetKey) -> UnsafeRawPointer{
        var pointerKey: UnsafeRawPointer
        
        switch key {
        case .random:
            var pointer: UnsafeRawPointer?
            repeat{
                pointer = UnsafeRawPointer(bitPattern: Int(arc4random()))
            }while pointer == nil
            pointerKey = pointer!
        case .hashable(let anyHashable):
            pointerKey = UnsafeRawPointer(bitPattern: anyHashable.hashValue)!
        case .pointer(let pointer):
            pointerKey = pointer
        }
        
        return pointerKey
    }
}
