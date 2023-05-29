//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

final public class EZObserveAnchorObject: Sendable{
    private let result: EZObserverTokenRemoveProtocol?
    deinit { result?.remove() }
    init(_ result: EZObserverTokenRemoveProtocol) { self.result = result }
}

public protocol EZObserverTokenRemoveProtocol: Sendable{
    func remove()
}

public struct EZObserverToken<Value>: EZObserverTokenRemoveProtocol, Sendable{
    private(set) var id: UInt
    private(set) weak var storage: (any EZObserversStorageProtocol<Value>)?
    private(set) var action: EZObserverAction<Value>
    private(set) var wreapper: EZObserverWrapperProtocol?
    public var anchorObject: EZObserveAnchorObject { EZObserveAnchorObject(self) }
    
    public var value: Value? {
        set(value){ if let value {storage?.set(value: value, .common)} }
        get{ storage?.get() }
    }
    
    @discardableResult
    public func use(_ type: EZSetType = .common) -> Self{
        guard let value else {return self}
        use(old: value, new: value, type)
        return self
    }
    
    func use(old: Value, new: Value, _ type: EZSetType){
        var wreapper = self.wreapper
        if case .changeWrapper(let newWrapper) = type { wreapper = newWrapper }
        action.use(value: EZObserverValue(old: old, new: new, wreapper: wreapper))
    }
    
    public func remove(){ storage?.remove(id: id) }
}

