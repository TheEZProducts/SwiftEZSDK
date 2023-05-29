//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation
import EZThreadSafetyKit

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
    func add(wrapper: EZObserverWrapperProtocol?, action: @escaping (EZObserverValue<Value>) -> ()) -> EZObserverToken<Value>
    func remove(id: UInt)
    func removeAll()
    
    func breakParentDependansy()
}

class EZObserversStorage<Value>: EZObserversStorageProtocol, @unchecked Sendable{
    @EZThreadSafety private var tokens = [EZObserverToken<Value>]()
    @EZThreadSafety private var idCounter: UInt = 0
    private var defaultWrapper: EZObserverWrapperProtocol?
    
    private var parent: (any EZObserversStorageProtocol)?
    var anchor: EZObserveAnchorObject?
    
    @EZThreadSafety private var value: Value
    
    func get() -> Value { value }
    func set(value: Value, _ type: EZSetType) {
        let old = self.value
        self.value = value
        if case .silent = type { return }
        useAll(old: old, type)
    }
    func signal(_ type: EZSetType) { set(value: value, type)  }
    
    @discardableResult
    func add(wrapper: EZObserverWrapperProtocol?, action: @escaping (EZObserverValue<Value>) -> ()) -> EZObserverToken<Value> {
        let token = EZObserverToken(
            id: idCounter,
            storage: self,
            action: .init(action: action),
            wreapper: wrapper ?? defaultWrapper
        )
        tokens.append(token)
        idCounter += 1
        return token
    }
    
    private func useAll(old: Value, _ type: EZSetType){
        tokens.forEach{ $0.use(old: old, new: value, type) }
    }
    
    func remove(id: UInt) {
        tokens.binaryRemove(keyPath: \.id, value: id)
    }
    
    func removeAll(){
        tokens = []
    }
    
    func breakParentDependansy() {
        parent = nil
        anchor = nil
    }
    
    init(
        value: Value,
        defaultWrapper: EZObserverWrapperProtocol? = nil,
        parent: (any EZObserversStorageProtocol)? = nil
    ) {
        self.value = value
        self.defaultWrapper = defaultWrapper
        self.parent = parent
    }
}
