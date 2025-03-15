//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation
import EZAsyncKit

public enum EZSetType{
    case common
    case silent
    case changeWrapper(EZObserverWrapperProtocol?)
}

protocol EZObserversStorageProtocol<Value>: AnyObject, Sendable{
    associatedtype Value
    
    func get() -> Value
    func set(value: Value, _ type: EZSetType)
    func signal(_ type: EZSetType)
    
    @discardableResult
    func add(wrapper: EZObserverWrapperProtocol?, action: @Sendable @escaping (EZObserverValue<Value>) -> ()) -> EZObserverToken<Value>
    
    func remove(id: UInt)
    func removeAll()
    
    func breakParentDependansy()
}

final class EZObserversStorage<Value>: EZObserversStorageProtocol, Sendable{
    private let tokens = EZSendableWrapper<[EZObserverToken<Value>]>(wrappedValue: [])
    private let idCounter = EZSendableWrapper<UInt>(wrappedValue: 0)
    private let defaultWrapper: EZObserverWrapperProtocol?
    
    private let parent: EZSendableWrapper<(any EZObserversStorageProtocol)?>
    let anchor = EZSendableWrapper<EZObserveAnchorObject?>(wrappedValue: nil)
    
    private let value: EZSendableWrapper<Value>
    
    func get() -> Value { value.wrappedValue }
    func set(value: Value, _ type: EZSetType) {
        let old = self.value.wrappedValue
        self.value.update{ $0 = value }
        if case .silent = type { return }
        useAll(old: old, type)
    }
    
    func signal(_ type: EZSetType) { set(value: value.wrappedValue, type)  }
    
    @discardableResult
    func add(wrapper: EZObserverWrapperProtocol?, action: @Sendable @escaping (EZObserverValue<Value>) -> ()) -> EZObserverToken<Value> {
        let token = idCounter.update{
            let token = EZObserverToken(
                id: $0,
                storage: self,
                action: .init(action: action),
                wrapper: wrapper ?? defaultWrapper
            )
            $0 += 1
            return token
        }
        tokens.update{ $0.append(token) }
        return token
    }
    
    private func useAll(old: Value, _ type: EZSetType){
        tokens.wrappedValue.forEach{ $0.use(old: old, new: value.wrappedValue, type) }
    }
    
    func remove(id: UInt) {
        tokens.update{ $0.binaryRemove(keyPath: \.id, value: id) }
    }
    
    func removeAll(){
        tokens.update{ $0 = [] }
    }
    
    func breakParentDependansy() {
        parent.update{ $0 = nil }
        anchor.update{ $0 = nil }
    }
    
    init(
        value: Value,
        defaultWrapper: EZObserverWrapperProtocol? = nil,
        parent: (any EZObserversStorageProtocol)? = nil
    ) {
        self.value = .init(wrappedValue: value)
        self.defaultWrapper = defaultWrapper
        self.parent = .init(wrappedValue: parent)
    }
}
