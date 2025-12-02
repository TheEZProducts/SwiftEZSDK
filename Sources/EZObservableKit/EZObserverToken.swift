//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

final public class EZObserveAnchorObject: Sendable {
    private let result: EZObserverTokenRemoveProtocol?
    deinit { result?.remove() }
    init(_ result: EZObserverTokenRemoveProtocol) { self.result = result }
}

public protocol EZObserverTokenRemoveProtocol: Sendable {
    func remove()
}

public protocol EZObserverTokenProtocol: EZObserverTokenRemoveProtocol {
    var anchorObject: EZObserveAnchorObject { get }
    
    @discardableResult
    func use(_ type: EZSetType) -> Self
}

public struct EZObserverToken<Value>: EZObserverTokenProtocol, Sendable {
    private(set) var id: UInt
    private(set) weak var storage: (any EZObserversStorageProtocol<Value>)?
    private(set) var action: EZObserverAction<Value>
    private(set) var removeAction: EZObserverAction<Value>?
    private(set) var wrapper: EZObserverWrapperProtocol?
    public var anchorObject: EZObserveAnchorObject { EZObserveAnchorObject(self) }
    
    public var value: Value? {
        nonmutating set(value){ if let value { storage?.set(value: value, .common) } }
        get{ storage?.get() }
    }
    
    @discardableResult
    public func use(_ type: EZSetType = .common) -> Self {
        guard let value else {return self}
        use(old: value, new: value, type)
        return self
    }
    
    func use(old: Value, new: Value, _ type: EZSetType) {
        var wrapper = self.wrapper
        if case .changeWrapper(let newWrapper) = type { wrapper = newWrapper }
        action.use(value: EZObserverValue(
            old: old,
            new: new,
            wrapper: wrapper,
            removeObserverAction: remove
        ))
    }
    
    public func remove() { storage?.remove(id: id) }
}

