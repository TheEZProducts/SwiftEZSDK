//
//  File.swift
//  
//
//  Created by Александр Сенин on 28.05.2023.
//

import Foundation

@propertyWrapper
public struct EZObservable<Value>: Sendable{
    private(set) var storage: any EZObserversStorageProtocol<Value>
    
    public var wrappedValue: Value{
        nonmutating set(value){ storage.set(value: value, .common) }
        get{ storage.get() }
    }
    
    public var projectedValue: Self {
        set(value){ self = value }
        get{ self }
    }
    
    public init(wrappedValue: Value, defaultWrapper: EZObserverWrapperProtocol? = nil){
        self.storage = EZObserversStorage(value: wrappedValue, defaultWrapper: defaultWrapper)
    }
    
    init(storage: any EZObserversStorageProtocol<Value>){
        self.storage = storage
    }
    
    @discardableResult
    public func set(value: Value, _ type: EZSetType = .common) -> Self{
        storage.set(value: value, type)
        return self
    }
    
    @discardableResult
    public func signal(_ type: EZSetType = .common) -> Self{
        storage.signal(type)
        return self
    }
    
    @discardableResult
    public func add(wrapper: EZObserverWrapperProtocol? = nil, action: @escaping (EZObserverValue<Value>) -> ()) -> EZObserverToken<Value>{
        storage.add(wrapper: wrapper, action: action)
    }
    
    @discardableResult
    public func remove(id: UInt) -> Self { storage.remove(id: id); return self }
    
    @discardableResult
    func removeAll() -> Self { storage.removeAll(); return self }
    
    @discardableResult
    public func breakParentDependansy() -> Self { storage.breakParentDependansy(); return self }
}

extension EZObservable{
    public func handler<NewValue>(wrapper: EZObserverWrapperProtocol? = nil, handler: @escaping (Value) -> (NewValue)) -> EZObservable<NewValue>{
        let hand = EZObserversStorage(value: handler(wrappedValue))
        let token = add(wrapper: nil) {[weak hand] in hand?.set(value: handler($0.new), .common) }
        hand.anchor = token.anchorObject
        return .init(storage: hand)
    }
}

extension EZObservable where Value: Hashable{
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        defaultValue: NewValue? = nil,
        _ map: [Value: NewValue]
    ) -> EZObservable<NewValue>?{
        if map.count == 0 {return nil}
        let defaultValue = defaultValue ?? map.first!.value
        return handler(wrapper: wrapper) { map[$0] ?? defaultValue }
    }
}

extension EZObservable where Value == Int{
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        defaultValue: NewValue? = nil,
        _ map: [NewValue]
    ) -> EZObservable<NewValue>?{
        if map.count == 0 {return nil}
        let defaultValue = defaultValue ?? map.first!
        return handler(wrapper: wrapper) { map[safe: $0] ?? defaultValue }
    }
    
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        defaultValue: NewValue? = nil,
        _ map: NewValue...
    ) -> EZObservable<NewValue>?{
        switcher(wrapper: wrapper, defaultValue: defaultValue, map)
    }
}

extension EZObservable where Value == Bool{
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        _ tValue: NewValue,
        _ fValue: NewValue
    ) -> EZObservable<NewValue>{
        return handler(wrapper: wrapper) { $0 ? tValue : fValue }
    }
}

