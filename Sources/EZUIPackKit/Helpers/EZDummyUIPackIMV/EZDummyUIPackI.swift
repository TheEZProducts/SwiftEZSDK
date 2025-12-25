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
>: EZUIPackI where Mediator.IActionProvider == Void {
    public var access: Mediator.AccessI!
}
#endif
