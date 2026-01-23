//
//  EZViewProtocol.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

@MainActor
public protocol EZViewProtocol<Mediator> {
    associatedtype Mediator: EZUIPackMediatorProtocol
    var access: Mediator.AccessV { get }
    
    init()
   
    func makeContext() -> Mediator.ContextV
    func create()
}


extension EZViewProtocol {
    public var packBridge: EZUIPackBridge {
        _read { yield access.packBridge }
    }
    
    public var viewModel: Mediator.ViewModel {
        _read { yield access.viewModel }
        nonmutating _modify { yield &access.viewModel }
    }
    
    public var inputI: Mediator.InputI {
        _read { yield access.inputI }
    }
}

extension EZViewProtocol {
    public func create(){}
}
#endif
