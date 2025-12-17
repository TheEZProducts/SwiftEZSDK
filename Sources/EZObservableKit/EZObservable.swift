//
//  File.swift
//  
//
//  Created by Александр Сенин on 28.05.2023.
//

import Foundation
import Combine

import EZAsyncKit
import EZHelpersKit

public protocol EZObservableProtocol<Value> {
    associatedtype Value
    
    @discardableResult
    func signal(_ type: EZSetType) -> Self
    
    @discardableResult
    func unknownAdd(
        wrapper: EZObserverWrapperProtocol?,
        action: @Sendable @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func unknownAddWithIsolation(
        isolation: (any Actor)?,
        wrapper: EZObserverWrapperProtocol?,
        action: @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol
    
    @discardableResult
    func unknownAddWithUnsafeIsolation(
        wrapper: EZObserverWrapperProtocol?,
        action: @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol
}

@propertyWrapper
public struct EZObservable<Value>: Sendable, EZObservableProtocol{
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
    public func set(value: Value, _ type: EZSetType = .common) -> Self {
        storage.set(value: value, type)
        return self
    }
    
    @discardableResult
    public func update<R>(type: EZSetType = .common, _ closure: (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R {
        try storage.update(type: type, closure)
    }
    
    @discardableResult
    public func signal(_ type: EZSetType = .common) -> Self{
        storage.signal(type)
        return self
    }
    
    @discardableResult
    public func remove(id: UInt) -> Self { storage.remove(id: id); return self }
    
    @discardableResult
    func removeAll() -> Self { storage.removeAll(); return self }
    
    @discardableResult
    public func breakParentDependansy() -> Self { storage.breakParentDependansy(); return self }
}

extension EZObservable{
    public func handler<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        handler: @Sendable @escaping (Value) -> (NewValue)
    ) -> EZObservable<NewValue> {
        let hand = EZObserversStorage(value: handler(wrappedValue))
        let token = add(wrapper: nil) {[weak hand] in hand?.set(value: handler($0.new), .common) }
        hand.setAnchor(token.anchorObject)
        return .init(storage: hand)
    }
}

extension EZObservable {
    @discardableResult
    public func add(
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @Sendable @escaping (EZObserverValue<Value>) -> (),
        removeAction: (@Sendable (EZObserverValue<Value>) -> ())? = nil
    ) -> EZObserverToken<Value> {
        storage.add(wrapper: wrapper, action: action, removeAction: removeAction)
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public func addWithIsolation(
        isolation: (any Actor)? = #isolation,
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @escaping (EZObserverValue<Value>) -> (),
        removeAction: ((EZObserverValue<Value>) -> ())? = nil
    ) -> EZObserverToken<Value> {
        if let isolation {
            add(
                wrapper: wrapper,
                action: wrappAction(isolation: isolation, action: action),
                removeAction: removeAction.map { wrappAction(isolation: isolation, action: $0) }
            )
        } else {
            addWithUnsafeIsolation(
                wrapper: wrapper,
                action: action,
                removeAction: removeAction
            )
        }
    }
    
    @discardableResult
    public func addWithUnsafeIsolation(
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @escaping (EZObserverValue<Value>) -> (),
        removeAction: ((EZObserverValue<Value>) -> ())? = nil
    ) -> EZObserverToken<Value> {
        let action = EZUnsafeSendableWrapper(action)
        let removeAction: (@Sendable (EZObserverValue<Value>) -> ())? = removeAction.map {
            let action = EZUnsafeSendableWrapper($0)
            return { action.value($0) }
        }
        return storage.add(
            wrapper: wrapper,
            action: { action.value($0) },
            removeAction: removeAction
        )
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    private func wrappAction(
        isolation: (any Actor),
        action: @escaping (EZObserverValue<Value>) -> ()
    ) -> @Sendable (EZObserverValue<Value>) -> () {
        if #available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *) {
            let action = EZUnsafeSendableWrapper(action)
            return { value in
                isolation.ezTaskImmediate { _ in action.value(value) }
            }
        } else {
            let isoletedAction = EZActorIsolator(isolation: isolation, value: action)
            if isolation is MainActor {
                return { value in
                    if Thread.isMainThread {
                        isoletedAction.unsafeUpdate{ $0(value) }
                    }else{
                        isoletedAction.update{ $0(value) }
                    }
                }
            } else {
                return { value in
                    isoletedAction.update{ $0(value) }
                }
            }
        }
    }
}

extension EZObservable {
    @discardableResult
    public func unknownAdd(
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @Sendable @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol{
        add(wrapper: wrapper) { action($0) }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public func unknownAddWithIsolation(
        isolation: (any Actor)? = #isolation,
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol {
        addWithIsolation(
            isolation: isolation,
            wrapper: wrapper,
            action: action
        )
    }
    
    @discardableResult
    public func unknownAddWithUnsafeIsolation(
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol {
        addWithUnsafeIsolation(
            wrapper: wrapper,
            action: action
        )
    }
}

extension EZObservable where Value: Hashable & Sendable {
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        defaultValue: NewValue? = nil,
        _ map: [Value: NewValue]
    ) -> EZObservable<NewValue>? {
        if map.count == 0 { return nil }
        let map = EZUnsafeSendableWrapper(map)
        let defaultValue = EZUnsafeSendableWrapper(defaultValue ?? map.value.first!.value)
        return handler(wrapper: wrapper) {
            (map.value[$0] ?? defaultValue.value)
        }
    }
}

extension EZObservable where Value == Int{
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        defaultValue: NewValue? = nil,
        _ map: [NewValue]
    ) -> EZObservable<NewValue>? {
        if map.count == 0 {return nil}
        let map = EZUnsafeSendableWrapper(map)
        let defaultValue = EZUnsafeSendableWrapper(defaultValue ?? map.value.first!)
        return handler(wrapper: wrapper) { map.value[safe: $0] ?? defaultValue.value }
    }
    
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        defaultValue: NewValue? = nil,
        _ map: NewValue...
    ) -> EZObservable<NewValue>? {
        switcher(wrapper: wrapper, defaultValue: defaultValue, map)
    }
}

extension EZObservable where Value == Bool{
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        _ tValue: NewValue,
        _ fValue: NewValue
    ) -> EZObservable<NewValue> {
        let tValue = EZUnsafeSendableWrapper(tValue)
        let fValue = EZUnsafeSendableWrapper(fValue)
        return handler(wrapper: wrapper) { $0 ? tValue.value : fValue.value }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension EZObservable {
    public func makeStream(
        wrapper: EZObserverWrapperProtocol? = nil,
        result: (EZObserverToken<Value>) -> () = {_ in}
    ) -> AsyncStream<EZObserverValue<Value>> {
        let (stream, continuation) = AsyncStream<EZObserverValue<Value>>.makeStream()
        let resultValue = add(wrapper: wrapper) { value in
            continuation.yield(value)
        } removeAction: { _ in
            continuation.finish()
        }
        result(resultValue)
        return stream
    }
}
