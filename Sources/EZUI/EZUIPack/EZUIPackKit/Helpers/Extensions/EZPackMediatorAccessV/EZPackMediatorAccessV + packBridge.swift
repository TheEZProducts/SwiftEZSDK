//
//  EZPackMediatorAccessV + packBridge.swift
//  EZSDK
//
//  Created by Александр Сенин on 15.02.2026.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation


extension EZPackMediatorAccessV where Mediator: EZUIPackMediatorProtocol {
    public var packBridge: EZUIPackBridge {
        get { mediator.packBridge }
    }
}


 
#endif
