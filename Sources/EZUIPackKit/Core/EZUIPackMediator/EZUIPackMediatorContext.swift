//
//  EZUIPackMediatorContext.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

import Foundation

#if canImport(UIKit) && !os(watchOS)

@MainActor
public struct EZUIPackMediatorContextI<M: EZUIPackMediatorProtocol> {
    public var actions: M.InputI
    public var viewModel: M.ViewModel
    
    public init(actions: M.InputI, viewModel: M.ViewModel) {
        self.actions = actions
        self.viewModel = viewModel
    }
}

@MainActor
public struct EZUIPackMediatorContextV<M: EZUIPackMediatorProtocol> {
    public var actions: M.InputV
    
    public init(actions: M.InputV) {
        self.actions = actions
    }
}

#endif
