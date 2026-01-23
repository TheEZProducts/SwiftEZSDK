//
//  EZDummyUIPackI.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//
#if canImport(UIKit) && !os(watchOS)
import Foundation

final public class EZDummyUIPackI<
    Mediator: EZUIPackMediatorProtocol
>: EZUIPackI where
    Mediator.ContextI == EZUIPackMediatorContextI<Mediator>,
    Mediator.InputI == Void,
    Mediator.ViewModel == Void
{
    public let access = Mediator.accessI
    
    public func makeContext() -> Mediator.ContextI {
        .init(actions: (), viewModel: ())
    }
}
#endif
