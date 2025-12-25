//
//  IMV.swift
//  Example
//
//  Created by Александр Сенин on 25.12.2025.
//

import UIKit

@MainActor
public protocol MediatorProtocol: AnyObject {
    associatedtype IActionProvider
    associatedtype VActionProvider
    
    associatedtype Storage
    associatedtype ViewModel
    
    typealias AccessI = MediatorAccessI<Self>
    typealias AccessV = EZMediatorWrapperV<Self>
    
    var storage: Storage { get set }
    var viewModel: ViewModel { get set }
    
    var iActions: IActionProvider { get set }
    var vActions: VActionProvider { get set }
}

extension MediatorProtocol {
    public var accessI: AccessI { .init(mediator: self) }
    public var accessV: AccessV { .init(mediator: self) }
}

@MainActor
public struct MediatorAccessI<Mediator: MediatorProtocol> {
    private let _mediator: Mediator
    
    public var storage: Mediator.Storage {
        _read { yield _mediator.storage }
        nonmutating _modify { yield &_mediator.storage }
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
public struct EZMediatorWrapperV<Mediator: MediatorProtocol> {
    private let _mediator: Mediator
    
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


public protocol InteractorProtocol: UIViewController {
    associatedtype Mediator: MediatorProtocol
    
    var access: Mediator.AccessI { get }
    
    init(mediator: Mediator, view: some ViewProtocol)
}


public protocol ViewProtocol: UIView {
    associatedtype Mediator: MediatorProtocol
    
    var access: Mediator.AccessV { get }
    
    init(mediator: Mediator)
}


@MainActor
public struct IMVMaker<
    Interactor: InteractorProtocol,
    Mediator: MediatorProtocol,
    View: ViewProtocol
> where Interactor.Mediator == Mediator, View.Mediator == Mediator {
    public static func make(mediator: Mediator) -> Interactor {
        Interactor(mediator: mediator, view: View(mediator: mediator))
    }
}

