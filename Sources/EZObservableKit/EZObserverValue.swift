//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

public protocol EZObserverValueProtocol<Value>{
    associatedtype Value
    var old: Value { get }
    var new: Value { get }
    
    var wrapper: EZObserverWrapperProtocol? { get }
}

public struct EZObserverValue<Value>: @unchecked Sendable, EZObserverValueProtocol{
    public private(set) var old: Value
    public private(set) var new: Value
    public private(set) var wrapper: EZObserverWrapperProtocol?
    private var removeObserverAction: () -> ()
    
    init(old: Value, new: Value, wrapper: EZObserverWrapperProtocol? = nil, removeObserverAction: @escaping () -> Void) {
        self.old = old
        self.new = new
        self.wrapper = wrapper
        self.removeObserverAction = removeObserverAction
    }
    
    public func removeObserver() { removeObserverAction() }
}

