//
//  EZUIPackM.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

@MainActor
public protocol EZUIPackMediatorProtocol: AnyObject, EZSharingProtocol {
    associatedtype InteractorActionProvider
    associatedtype ViewActionProvider
    
    associatedtype Storage
    associatedtype ViewModel
    
    typealias AccessI = EZMediatorWrapperI<Self>
    typealias AccessV = EZMediatorWrapperV<Self>
    
    var packBridge: EZUIPackBridge { get set }
    
    func didInitialize()
        
    var storage: Storage { get set }
    var viewModel: ViewModel { get set }
    
    var iActions: InteractorActionProvider { get set }
    var vActions: ViewActionProvider { get set }
    
    init()
}

extension EZUIPackMediatorProtocol {
    public var shared: EZSharedStorage? { nil }
    public var parentShered: EZSharedStorage {
        packBridge.pack?.parentShered ?? .init()
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

extension EZUIPackMediatorProtocol where InteractorActionProvider == Void {
    public var iActions: InteractorActionProvider {
        set {}
        get { () }
    }
}

extension EZUIPackMediatorProtocol where ViewActionProvider == Void {
    public var vActions: ViewActionProvider {
        set {}
        get { () }
    }
}


@MainActor
public protocol EZUIPackWithMediatorIProtocol {
    associatedtype Mediator: EZUIPackMediatorProtocol
    var access: Mediator.AccessI! { get set }
    init(mediator: Mediator)
}

@MainActor
public protocol EZUIPackWithMediatorVProtocol {
    associatedtype Mediator: EZUIPackMediatorProtocol
    var access: Mediator.AccessV! { get set }
    init(mediator: Mediator)
}

@MainActor
open class EZUIPackMediator {
    @MainActor
    required public init(){}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackMediator: ObservableObject{}

public typealias EZUIPackM = EZUIPackMediatorProtocol & EZUIPackMediator


@MainActor
public struct EZMediatorWrapperI<Mediator: EZUIPackMediatorProtocol> {
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
    
    public var vActions: Mediator.ViewActionProvider {
        _read { yield _mediator.vActions }
    }
    
    init(mediator: Mediator) {
        self._mediator = mediator
    }
}

@MainActor
public struct EZMediatorWrapperV<Mediator: EZUIPackMediatorProtocol> {
    private let _mediator: Mediator
    
    public var packBridge: EZUIPackBridge {
        _read { yield _mediator.packBridge }
    }
    
    public var viewModel: Mediator.ViewModel {
        _read { yield _mediator.viewModel }
        nonmutating _modify { yield &_mediator.viewModel }
    }
    
    public var iActions: Mediator.InteractorActionProvider {
        _read { yield _mediator.iActions }
    }
    
    init(mediator: Mediator) {
        self._mediator = mediator
    }
}

#endif
