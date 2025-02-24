//
//  EZDummyUIPackI.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

import Foundation

final public class EZDummyUIPackI<Mediator: EZUIPackMediatorProtocol>: EZUIPackI {
    public var mediator: Mediator!
    public required init(){}
}
