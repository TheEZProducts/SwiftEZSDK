//
//  EZMappedAccess.swift
//  EZSDK
//
//  Created by Александр Сенин on 06.01.2026.
//

import Foundation

@dynamicMemberLookup
open class EZMappedAccess<Object: AnyObject, AccessMap> {
    private let object: () -> (Object)
    private let map: AccessMap
    
    public subscript<Value>(dynamicMember key: KeyPath<AccessMap, KeyPath<Object, Value>>) -> Value {
        get { object()[keyPath: map[keyPath: key]] }
    }
    
    public subscript<Value>(dynamicMember key: KeyPath<AccessMap, ReferenceWritableKeyPath<Object, Value>>) -> Value {
        get { object()[keyPath: map[keyPath: key]] }
        set { object()[keyPath: map[keyPath: key]] = newValue }
    }
    
    public init(_ object: @escaping () -> (Object), accessMap: AccessMap) {
        self.object = object
        self.map = accessMap
    }
    
    public convenience init(_ object: Object, accessMap: AccessMap) {
        self.init({ object }, accessMap: accessMap)
    }
}
