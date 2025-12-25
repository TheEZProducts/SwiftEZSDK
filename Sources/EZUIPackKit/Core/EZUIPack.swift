//
//  EZUIPack1.swift
//  EZSDK
//
//  Created by Александр Сенин on 24.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

@MainActor
public protocol EZUIPackProtocol: AnyObject {
    associatedtype Interactor: EZUIPackInteractorProtocol where Interactor.Mediator == Mediator
    associatedtype Mediator: EZUIPackMediatorProtocol
    associatedtype View: EZUIPackViewProtocol where View.Mediator == Mediator
    
    var interactor: Interactor? { get }
    var mediator: Mediator { get }
    var view: View { get }
    
    var transitionController: EZTransitionControllerProtocol? { get set }
    
    func loadView(frame: CGRect) -> UIView
    func viewDidLoad()
    func didMove(toParent parent: UIViewController?)
    func viewWillAppear(_ animated: Bool)
    
    @available(iOS 13.0, tvOS 13.0, *)
    func viewIsAppearing(_ animated: Bool)
    
    func viewDidLayoutSubviews()
    func viewDidAppear(_ animated: Bool)

    func viewWillDisappear(_ animated: Bool)
    func viewDidDisappear(_ animated: Bool)
}

@MainActor
open class EZUIPack<
    I: EZUIPackInteractorProtocol,
    M: EZUIPackMediatorProtocol,
    V: EZUIPackViewProtocol
>: EZUIPackProtocol where I.Mediator == M, V.Mediator == M {
    public weak var interactor: I?
    public let mediator: M
    public let view: V
    
    public var transitionController: (any EZTransitionControllerProtocol)?
    
    public weak var parentController: UIViewController?
    
    public var isStarted = false
    public var willAppear: Bool = false
    private var openAction: (() -> Void)?
    
    public init(mediator: M, view: V) {
        self.mediator = mediator
        self.view = view
    }
    
    open func setup(interactor: I) {
        self.interactor = interactor
        mediator.packBridge.pack = self
        mediator.didInitialize()
        interactor.didInitialize()
        view.didInitialize()
        mediator.iActions = interactor.setupActions()
        if let actions = view.setupActions() { mediator.vActions = actions }
    }
    
    open func loadView(frame: CGRect) -> UIView {
        let uiView = self.view.getView()
        uiView.frame = frame
        uiView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        uiView.layer.masksToBounds = true
        return uiView
    }
    
    open func viewDidLoad() {
        view.viewDidLoad()
    }
    
    open func didMove(toParent parent: UIViewController?){
        self.parentController = parent
    }
    
    open func viewWillAppear(_ animated: Bool){
        view.viewWillAppear(animated)
        
        resizeToPreferredContentSize()
        willAppear = true
        
        performWithTransitionCoordinator{[weak self] in
            self?.open()
        }
    }
    
    open func open(){
        UIView.performWithoutAnimation {
            if !isStarted {
                interactor?.start()
                view.create()
                interactor?.didCreate()
                isStarted = true
            }
            
            interactor?.willOpen()
            view.willOpen()
        }
    
        view.animateOpen()
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    open func viewIsAppearing(_ animated: Bool) {
        view.viewIsAppearing(animated)
    }
    
    open func viewDidLayoutSubviews(){
        guard willAppear else { return }
        willAppear = false
        openAction?()
        openAction = nil
        interactor?.didInstall()
        view.didInstall()
    }
    
    open func viewDidAppear(_ animated: Bool) {
        view.viewDidAppear(animated)
        interactor?.didOpen()
        view.didOpen()
    }

    open func viewWillDisappear(_ animated: Bool) {
        view.viewWillDisappear(animated)
        interactor?.willClose()
        view.willClose()
        
        performWithTransitionCoordinator{[view] in
            view.animateClose()
        }
    }

    open func viewDidDisappear(_ animated: Bool) {
        view.viewDidDisappear(animated)
        interactor?.didClose()
        view.didClose()
    }
    
    private func resizeToPreferredContentSize(){
        if
            let size = interactor?.preferredContentSize,
            size != .zero
        {
            interactor?.view.frame.size = size
            interactor?.view.layoutIfNeeded()
        }
    }
    
    private func performWithTransitionCoordinator(action: @escaping () -> ()) {
        var animated = false
        if
            let transitionCoordinator = interactor?.firstTransitionCoordinator ??
                parentController?.firstTransitionCoordinator
        {
            animated = transitionCoordinator.animate {_ in
                action()
            }
        }
        
        if !animated {
            openAction = action
        }
    }
}

extension EZUIPack {
    public static func make(customData: Interactor.CustomInitData) -> I {
        make(.init(), customData: customData)
    }
    
    public static func make(_ mediator: M, customData: Interactor.CustomInitData) -> I {
        let view = makeView(mediator: mediator)
        let pack = EZUIPack(mediator: mediator, view: view)
        
        let interactor = makeInteractor(pack: pack, customData: customData)
        interactor.access = mediator.accessI
        pack.setup(interactor: interactor)
        
        return interactor
    }
    
    public static func makeInteractor(pack: EZUIPack, customData: Interactor.CustomInitData) -> I {
        .init(pack: pack, customData: customData)
    }
    
    public static func makeView(mediator: M) -> V {
        .init(mediator: mediator)
    }
}

extension EZUIPack where I.CustomInitData == () {
    public static func make() -> I {
        make(customData: ())
    }
    
    public static func make(_ mediator: M) -> I {
        make(mediator, customData: ())
    }
}

#endif
