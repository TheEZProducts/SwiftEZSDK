//
//  IMV.swift
//  Example
//
//  Created by Александр Сенин on 07.01.2026.
//

import SwiftUI

@MainActor
public protocol IMVMediatorProtocol: AnyObject {
    associatedtype IActionProvider
    associatedtype VActionProvider
    
    associatedtype ViewModel: ObservableObject
    
    typealias AccessI = IMVMediatorAccessI<Self>
    typealias AccessV = IMVMediatorAccessV<Self>
    
    var viewModel: ViewModel { get set }
    
    var inputI: IActionProvider { get set }
    var inputV: VActionProvider { get set }
    
    func didInitialize()
    
    init()
}

extension IMVMediatorProtocol {
    public var accessI: AccessI { .init(mediator: self) }
    public var accessV: AccessV { .init(mediator: self) }
}

@MainActor
public struct IMVMediatorAccessI<Mediator: IMVMediatorProtocol> {
    private let _mediator: Mediator
    
    public var viewModel: Mediator.ViewModel {
        _read { yield _mediator.viewModel }
        nonmutating _modify { yield &_mediator.viewModel }
    }
    
    public var inputV: Mediator.VActionProvider {
        _read { yield _mediator.inputV }
    }
    
    init(mediator: Mediator) {
        self._mediator = mediator
    }
}

@MainActor
public struct IMVMediatorAccessV<Mediator: IMVMediatorProtocol> {
    private let _mediator: Mediator
    
    public var viewModel: Mediator.ViewModel {
        _read { yield _mediator.viewModel }
        nonmutating _modify { yield &_mediator.viewModel }
    }
    
    public var inputI: Mediator.IActionProvider {
        _read { yield _mediator.inputI }
    }
    
    init(mediator: Mediator) {
        self._mediator = mediator
    }
}


@MainActor
public protocol IMVInteractorProtocol: AnyObject {
    associatedtype Mediator: IMVMediatorProtocol
    
    var access: Mediator.AccessI { get }
    
//    func makeContext() -> Mediator.ContextI
    func didInitialize()
    
    func onOpen()
    func onClose()
    
    init(mediator: Mediator)
}

@MainActor
public protocol IMVViewProtocol: View, Equatable {
    associatedtype Mediator: IMVMediatorProtocol
    
    var access: Mediator.AccessV { get }
    
    func didInitialize()
    
    init(mediator: Mediator)
}

extension IMVViewProtocol where Self: View {
    nonisolated
    public static func ==(l: Self, r: Self) -> Bool { false }
}

@MainActor
class Pack<
    I: IMVInteractorProtocol,
    M: IMVMediatorProtocol,
    V: IMVViewProtocol
> where I.Mediator == M, V.Mediator == M {
    let interactor: I
    let mediator: M
    let view: V
    
    init() {
        mediator = .init()
        interactor = .init(mediator: mediator)
        let view = V(mediator: mediator)
        self.view = view
        
        mediator.didInitialize()
        interactor.didInitialize()
        view.didInitialize()
    }
}


public struct IMVPackView<
    I: IMVInteractorProtocol,
    M: IMVMediatorProtocol,
    V: IMVViewProtocol
>: View where I.Mediator == M, V.Mediator == M {
//    let interactor: I
//    let mediator: M
//    let view: V
        
    @State private var pack: Pack<I,M,V>?
//    @ObservedObject private var viewModel: M.ViewModel
    
    public var body: some View {
        pack?.view
//            .onAppear {[weak interactor] in
//                interactor?.onOpen()
//            }
//            .onDisappear {[weak interactor] in
//                interactor?.onClose()
//            }
    }
    
    init() {
        if pack == nil {
            pack = .init()
        }
//        mediator = .init()
//        interactor = .init(mediator: mediator)
//        let view = V(mediator: mediator)
//        self.view = view
//        
//        viewModel = mediator.viewModel
//        
//        mediator.didInitialize()
//        interactor.didInitialize()
//        view.didInitialize()
    }
}


typealias SUITestPackView = IMVPackView<SUITestI, SUITestM, SUITestV>

class SUITestM: IMVMediatorProtocol {
    var viewModel = ViewModel()
    class ViewModel: ObservableObject {
        @Published var i = 0
    }
    
    weak var inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
        func incrice()
    }
    
    var inputV = InputV()
    struct InputV {
        
    }
    
    func didInitialize() {
        
    }
    
    required init() {}
}


class SUITestI: IMVInteractorProtocol {
    let access: SUITestM.AccessI
    
    func didInitialize() {
        
    }
    
    func onOpen() {
        
    }
    
    func onClose() {
        
    }
    
    required init(mediator: SUITestM) {
        self.access = mediator.accessI
        mediator.inputI = self
    }
}

extension SUITestI: SUITestM.InputIProtocol {
    func incrice() {
        access.viewModel.i += 1
    }
}


struct SUITestV: IMVViewProtocol {
    let access: SUITestM.AccessV
    
    @State var i = 0
    
    var body: some View {
        ZStack {
            Color.blue
            VStack {
                Button {
                    i += 1
//                    access.inputI?.incrice()
                } label: {
                    Text("Hello, \(i)")
                }
                SUITest1PackView()
            }
        }
    }
    
    func didInitialize() {
        
    }
    
    init(mediator: SUITestM) {
        self.access = mediator.accessV
    }
}


typealias SUITest1PackView = IMVPackView<SUITest1I, SUITest1M, SUITest1V>

class SUITest1M: IMVMediatorProtocol {
    var viewModel = ViewModel()
    class ViewModel: ObservableObject {
        @Published var i = 0
    }
    
    weak var inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
        func incrice()
    }
    
    var inputV = InputV()
    struct InputV {
        
    }
    
    func didInitialize() {
        
    }
    
    required init() {}
}


class SUITest1I: IMVInteractorProtocol {
    let access: SUITest1M.AccessI
    
    func didInitialize() {
        
    }
    
    func onOpen() {
        
    }
    
    func onClose() {
        
    }
    
    required init(mediator: SUITest1M) {
        self.access = mediator.accessI
        mediator.inputI = self
    }
}

extension SUITest1I: SUITest1M.InputIProtocol {
    func incrice() {
        access.viewModel.i += 1
    }
}


struct SUITest1V: IMVViewProtocol {
    let access: SUITest1M.AccessV
    
    var body: some View {
        ZStack {
            Color.green
            Button {
                access.inputI?.incrice()
            } label: {
                Text("Hello, \(access.viewModel.i)")
            }
        }
    }
    
    func didInitialize() {
        
    }
    
    init(mediator: SUITest1M) {
        self.access = mediator.accessV
    }
}
