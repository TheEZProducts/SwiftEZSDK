//
//  EZUIPackStorage.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit


@MainActor
open class EZUIPackStorage<
    I: EZUIPackInteractorProtocol,
    M: EZUIPackMediatorProtocol,
    V: EZUIPackViewProtocol
> where I.Mediator == M, V.Mediator == M{
    public var packBridge = EZUIPackBridge()
    public weak var parentController: UIViewController?
    
    public var transitionController: EZTransitionControllerProtocol?
    
    public var interactor: I
    public var mediator: M
    public var view: V
    
    public var isStarted = false
    public var willAppear: Bool = false
    
    public init(mediator: M) {
        self.mediator = mediator
        self.interactor = .init(mediator: self.mediator)
        self.view = .init(mediator: self.mediator)
    }
    
    public convenience init() {
        self.init(mediator: .init())
    }
    
    open func setupPack(pack: (any EZUIPackProtocol)){
        self.packBridge.pack = pack
        self.mediator.packBridge.pack = pack
        mediator.didInitialize()
        interactor.didInitialize()
        view.didInitialize()
        packBridge.pack?.didInitialize()
        if let actions = interactor.setupActions() { mediator.iActions = actions }
        if let actions = view.setupActions() { mediator.vActions = actions }
    }
    
    open func loadView() -> UIView{
        let uiView = self.view.getView()
        uiView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        uiView.layer.masksToBounds = true
        return uiView
    }
    
    open func viewDidLoad() {
        interactor.viewDidLoad()
        view.viewDidLoad()
    }
    
    open func didMove(toParent parent: UIViewController?){
        self.parentController = parent
    }
    
    open func viewWillAppear(_ animated: Bool){
        interactor.viewWillAppear(animated)
        view.viewWillAppear(animated)
        
        resizeToPreferredContentSize()
        willAppear = true
        
        performWithTransitionCoordinator{[weak self] in
            self?.open()
        }
    }
    
    open func open(){
        UIView.performWithoutAnimation {
            if !isStarted{
                interactor.start()
                view.create()
                interactor.didCreate()
                isStarted = true
            }
            
            interactor.willOpen()
            view.willOpen()
        }
    
        view.animateOpen()
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    open func viewIsAppearing(_ animated: Bool) {
        interactor.viewIsAppearing(animated)
        view.viewIsAppearing(animated)
    }
    
    open func viewDidLayoutSubviews(){
        guard willAppear else { return }
        willAppear = false
        interactor.didInstall()
        view.didInstall()
    }
    
    open func viewDidAppear(_ animated: Bool) {
        interactor.viewDidAppear(animated)
        view.viewDidAppear(animated)
        interactor.didOpen()
        view.didOpen()
    }

    open func viewWillDisappear(_ animated: Bool) {
        interactor.viewWillDisappear(animated)
        view.viewWillDisappear(animated)
        interactor.willClose()
        view.willClose()
        
        performWithTransitionCoordinator{[view] in
            view.animateClose()
        }
    }

    open func viewDidDisappear(_ animated: Bool) {
        interactor.viewDidDisappear(animated)
        view.viewDidDisappear(animated)
        interactor.didClose()
        view.didClose()
    }
    
    private func resizeToPreferredContentSize(){
        if
            let size = packBridge.pack?.preferredContentSize,
            size != .zero
        {
            packBridge.pack?.view.frame.size = size
            packBridge.pack?.view.layoutIfNeeded()
        }
    }
    
    private func performWithTransitionCoordinator(action: @escaping () -> ()) {
        var animated = false
        if
            let transitionCoordinator = packBridge.pack?.firstTransitionCoordinator ??
                parentController?.firstTransitionCoordinator
        {
            animated = transitionCoordinator.animate{_ in
                action()
            }
        }
        
        if !animated {
            action()
        }
    }
}

extension UIViewController{
    var firstPreferredContentSize: CGSize? {
        preferredContentSize != .zero ? preferredContentSize : parent?.firstPreferredContentSize
    }
}
#endif
