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
}

