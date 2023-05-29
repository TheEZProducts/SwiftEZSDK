//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

public struct EZObserverValue<Value>: @unchecked Sendable{
    public private(set) var old: Value
    public private(set) var new: Value
    public private(set) var wreapper: EZObserverWrapperProtocol?
}

