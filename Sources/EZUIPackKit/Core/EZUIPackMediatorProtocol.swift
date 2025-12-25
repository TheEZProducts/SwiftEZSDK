//
//  EZUIPackM.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

@MainActor
public protocol EZUIPackBaseMediatorProtocol: AnyObject {
    var packBridge: EZUIPackBridge { get set }
}

@MainActor
public protocol EZUIPackMediatorProtocol: EZUIPackBaseMediatorProtocol {
    associatedtype IActionProvider
    associatedtype VActionProvider
    
    associatedtype Storage
    associatedtype ViewModel
    
    typealias AccessI = EZMediatorAccessI<Self>
    typealias AccessV = EZMediatorAccessV<Self>
    
    func didInitialize()
        
    var storage: Storage { get set }
    var viewModel: ViewModel { get set }
    
    var iActions: IActionProvider { get set }
    var vActions: VActionProvider { get set }
    
    init()
}

extension EZUIPackMediatorProtocol {
    public var parentShered: EZSharedStorage {
        packBridge.pack?.interactor?.parentShered ?? .init()
    }
    
    public func didInitialize() {}
}

extension EZUIPackMediatorProtocol {
    public var accessI: AccessI { .init(mediator: self) }
    public var accessV: AccessV { .init(mediator: self) }
}

extension EZUIPackMediatorProtocol where Storage == Void {
    public var storage: Storage {
        set {}
        get { () }
    }
}

extension EZUIPackMediatorProtocol where ViewModel == Void {
    public var viewModel: ViewModel {
        set {}
        get { () }
    }
}

extension EZUIPackMediatorProtocol where IActionProvider == Void {
    public var iActions: IActionProvider {
        set {}
        get { () }
    }
}

extension EZUIPackMediatorProtocol where VActionProvider == Void {
    public var vActions: VActionProvider {
        set {}
        get { () }
    }
}


@MainActor
open class EZUIPackMediator: EZUIPackBaseMediatorProtocol {
    public var packBridge = EZUIPackBridge()
    
    required public init(){}
}

public typealias EZUIPackM = EZUIPackMediatorProtocol & EZUIPackMediator

@MainActor
public struct EZMediatorAccessI<Mediator: EZUIPackMediatorProtocol> {
    private let _mediator: Mediator
    
    public var packBridge: EZUIPackBridge {
        _read { yield _mediator.packBridge }
    }
    
    public var storage: Mediator.Storage {
        _read { yield _mediator.storage }
        nonmutating _modify { yield &_mediator.storage }
    }
    
    public var parentShered: EZSharedStorage {
        _read { yield _mediator.parentShered }
    }
    
    public var viewModel: Mediator.ViewModel {
        _read { yield _mediator.viewModel }
        nonmutating _modify { yield &_mediator.viewModel }
    }
    
    public var vActions: Mediator.VActionProvider {
        _read { yield _mediator.vActions }
    }
    
    init(mediator: Mediator) {
        self._mediator = mediator
    }
}

@MainActor
public struct EZMediatorAccessV<Mediator: EZUIPackMediatorProtocol> {
    private let _mediator: Mediator
    
    public var packBridge: EZUIPackBridge {
        _read { yield _mediator.packBridge }
    }
    
    public var viewModel: Mediator.ViewModel {
        _read { yield _mediator.viewModel }
        nonmutating _modify { yield &_mediator.viewModel }
    }
    
    public var iActions: Mediator.IActionProvider {
        _read { yield _mediator.iActions }
    }
    
    init(mediator: Mediator) {
        self._mediator = mediator
    }
}

#endif
