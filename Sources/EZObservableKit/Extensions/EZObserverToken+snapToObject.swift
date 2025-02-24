//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

#if canImport(EZAssociatedKit)
import EZAssociatedKit

extension EZObserverTokenProtocol{
    @discardableResult
    public func snapToObject(_ object: AnyObject) -> Self{
        EZAssociated(object).set(anchorObject, .random, .OBJC_ASSOCIATION_RETAIN)
        return self
    }
}
#endif
