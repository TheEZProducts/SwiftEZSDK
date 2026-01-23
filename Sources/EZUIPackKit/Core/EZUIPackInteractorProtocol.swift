//
//  EZUIPackI.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation
import UIKit

@MainActor
public protocol EZUIPackBaseInteractorProtocol: UIViewController, EZTransitionControlledProtocol {
    associatedtype CustomInitData = Void
    
    var pack: (any EZUIPackProtocol) { get }
}

extension EZUIPackBaseInteractorProtocol {
    public var transitionController: (any EZTransitionControllerProtocol)? {
        _read { yield pack.transitionController }
        _modify { yield &pack.transitionController }
    }
}
 
@MainActor
public protocol EZUIPackInteractorProtocol: EZUIPackBaseInteractorProtocol, EZSharingProtocol {
    associatedtype Mediator: EZUIPackMediatorProtocol
    var access: Mediator.AccessI { get }
    
    func makeContext() -> Mediator.ContextI
    func didInitialize()
    func start()
    func didCreate()
    func willOpen()
    func didOpen()
    func didInstall()
    func willClose()
    func didClose()
}

extension EZUIPackInteractorProtocol {
    public var shared: EZSharedStorage? { nil }
}

extension EZUIPackInteractorProtocol {
    public var viewModel: Mediator.ViewModel {
        _read { yield access.viewModel }
        _modify { yield &access.viewModel }
    }
    
    public var inputV: Mediator.InputV {
        _read { yield access.inputV }
    }
}

extension EZUIPackInteractorProtocol {
    public func didInitialize(){}
    public func start(){}
    public func didCreate(){}
    public func willOpen(){}
    public func didOpen(){}
    public func didInstall(){}
    public func willClose(){}
    public func didClose(){}
}

#endif
