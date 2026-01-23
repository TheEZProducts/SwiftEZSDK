//
//  EZDummyUIPackV.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

final public class EZDummyUIPackV<
    Mediator: EZUIPackMediatorProtocol
>: EZUIPackV where
    Mediator.ContextV == EZUIPackMediatorContextV<Mediator>,
    Mediator.InputV == Void
{
    public let access = Mediator.accessV
    
    public func makeContext() -> Mediator.ContextV { .init(actions: ()) }
}
#endif
