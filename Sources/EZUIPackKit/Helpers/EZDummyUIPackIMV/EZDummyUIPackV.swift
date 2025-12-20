//
//  EZDummyUIPackV.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

final public class EZDummyUIPackV<Mediator: EZUIPackMediatorProtocol>: EZUIPackV {
    public var mediator: Mediator!
}
#endif
