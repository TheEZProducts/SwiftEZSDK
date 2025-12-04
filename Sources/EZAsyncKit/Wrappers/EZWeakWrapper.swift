//
//  EZWeakWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 05.03.2025.
//

import Foundation

public struct EZWeakWrapper<Value: AnyObject> {
    nonisolated(unsafe)
    public private(set) weak var value: Value?
    
    public init(value: Value?) {
        self.value = value
    }
}

extension EZWeakWrapper: Sendable where Value: Sendable {}


