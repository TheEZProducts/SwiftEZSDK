//
//  EZDummyUIPackI.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//
#if canImport(UIKit) && !os(watchOS)
import Foundation

final public class EZDummyUIPackI<Mediator: EZUIPackMediatorProtocol>: EZUIPackI {
    public var mediator: Mediator.AccessI!
    
    public var access: Mediator.AccessI!
    
    public required init(){}
}
#endif
