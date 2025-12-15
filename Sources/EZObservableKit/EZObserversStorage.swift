//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

import EZAsyncKit
import EZHelpersKit

public enum EZSetType: Sendable {
    case common
    case silent
    case changeWrapper(EZObserverWrapperProtocol?)
}

protocol EZObserversStorageProtocol<Value>: AnyObject, Sendable {
    associatedtype Value
    
    func update<R>(type: EZSetType, _ closure: (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R
    func get() -> Value
    func set(value: Value, _ type: EZSetType)
    func signal(_ type: EZSetType)
    
    @discardableResult
    func add(
        wrapper: EZObserverWrapperProtocol?,
        action: @Sendable @escaping (EZObserverValue<Value>) -> (),
        removeAction: (@Sendable (EZObserverValue<Value>) -> ())?
    ) -> EZObserverToken<Value>
    
    func remove(id: UInt)
    func removeAll()
    
    func breakParentDependansy()
}

extension EZObserversStorage {
    fileprivate struct Storage: ~Copyable {
        fileprivate var tokens = [EZObserverToken<Value>]()
        fileprivate var idCounter: UInt = 0
        
        fileprivate var parent: (any EZObserversStorageProtocol)? = nil
        fileprivate var anchor: EZObserveAnchorObject?
    }
}

final class EZObserversStorage<Value>: EZObserversStorageProtocol, Sendable {
    private let storage = EZMutex(Storage())
    
    private let defaultWrapper: EZObserverWrapperProtocol?
    
    nonisolated(unsafe)
    private let value: EZRecursiveMutex<Value>
    
    
    func get() -> Value { value.get() }
    func set(value: Value, _ type: EZSetType) {
        update(type: type, { $0.value = value })
    }
    
    func update<R>(type: EZSetType, _ closure: (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R {
        let (old, result) = try value.withLock {
            let old = $0.value
            return (old, try closure($0))
        }
        if case .silent = type { return result }
        useAll(old: old, type)
        return result
    }
    
    func signal(_ type: EZSetType) { set(value: value.get(), type)  }
    
    @discardableResult
    func add(
        wrapper: EZObserverWrapperProtocol?,
        action: @Sendable @escaping (EZObserverValue<Value>) -> (),
        removeAction: (@Sendable (EZObserverValue<Value>) -> ())? = nil
    ) -> EZObserverToken<Value> {
        storage.withLock {
            let token = EZObserverToken(
                id: $0.value.idCounter,
                storage: self,
                action: .init(action: action),
                removeAction: removeAction.map { .init(action: $0) },
                wrapper: wrapper ?? defaultWrapper
            )
            $0.value.idCounter += 1
            $0.value.tokens.append(token)
            return token
        }
    }
    
    private func useAll(old: Value, _ type: EZSetType) {
        let value = value.get()
        storage
            .withLock { $0.value.tokens }
            .forEach { $0.use(old: old, new: value, type) }
    }
    
    func remove(id: UInt) {
        guard
            let tocken = storage.withLock({
                $0.value.tokens.binaryRemove(keyPath: \.id, value: id)
            })
        else { return }
        let value = self.value.get()
        tocken.removeAction?.use(value: .init(
            old: value,
            new: value,
            wrapper: tocken.wrapper,
            removeObserverAction: {}
        ))
    }
    
    func removeAll() {
        let old = storage.withLock { access in
            defer { access.value.tokens = [] }
            return access.value.tokens
        }
        let value = self.value.get()
        old.forEach {
            $0.removeAction?.use(value: .init(
                old: value,
                new: value,
                wrapper: $0.wrapper,
                removeObserverAction: {}
            ))
        }
    }
    
    func breakParentDependansy() {
        storage.withLock {
            $0.value.parent = nil
            $0.value.anchor = nil
        }
    }
    
    func setAnchor(_ anchor: EZObserveAnchorObject) {
        storage.withLock { $0.value.anchor = anchor }
    }
    
    init(
        value: Value,
        defaultWrapper: EZObserverWrapperProtocol? = nil,
        parent: (any EZObserversStorageProtocol)? = nil
    ) {
        self.value = .init(value)
        self.defaultWrapper = defaultWrapper
        storage.withLock { $0.value.parent = parent }
    }
}
