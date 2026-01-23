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
    var mediator: Mediator? { get }
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
    
    func setup(interactor: Interactor)
    
    init(view: View)
}

@MainActor
open class EZUIPack<
    I: EZUIPackInteractorProtocol,
    M: EZUIPackMediatorProtocol,
    V: EZUIPackViewProtocol
>: EZUIPackProtocol where I.Mediator == M, V.Mediator == M {
    public private(set) weak var interactor: I?
    public private(set) var mediator: M?
    public let view: V
    
    public var transitionController: (any EZTransitionControllerProtocol)?
    
    public weak var parentController: UIViewController?
    
    public var isStarted = false
    public var willAppear: Bool = false
    private var openAction: (() -> Void)?
    
    public required init(view: V) {
        self.view = view
    }
    
    open func setup(interactor: I) {
        let mediator = M(
            contextI: interactor.makeContext(),
            contextV: view.makeContext()
        )
        mediator.packBridge.pack = self
        interactor.access.setMediator(mediator)
        view.access.setMediator(mediator)
        
        self.interactor = interactor
        self.mediator = mediator
        
        mediator.didInitialize()
        interactor.didInitialize()
        view.didInitialize()
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
                parentController?.firstTransitionCoordinator,
            transitionCoordinator.transitionDuration > 0
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

@MainActor
public final class EZPackMaker: Sendable {
    private static var currentSession = [(any MakeSessionProtocol)]()
    
    public static func make<Pack: EZUIPackProtocol>(
        packType: Pack.Type = Pack.self,
        interactor maker: () -> Pack.Interactor
    ) -> Pack.Interactor {
        let session = MakeSession<Pack>()
        
        currentSession.append(session)
        defer { currentSession.removeLast() }
        
        return session.make(interactor: maker)
    }
    
    private static func getCurrentSession() -> any MakeSessionProtocol {
        guard let currentSession = currentSession.last else { fatalError("Call EZPackMaker.make(...) first.") }
        return currentSession
    }
    
    public static func getPack() -> (any EZUIPackProtocol) {
        getCurrentSession().getPack()
    }
    
    @MainActor
    protocol MakeSessionProtocol {
        func getPack() -> (any EZUIPackProtocol)
    }
    
    @MainActor
    final class MakeSession<Pack: EZUIPackProtocol>: MakeSessionProtocol, Sendable {
        private var pack: Pack = .init(view: .init())
        
        func getPack() -> any EZUIPackProtocol { pack }
        
        func make(interactor maker: () -> Pack.Interactor) -> Pack.Interactor {
            let interactor = maker()
            pack.setup(interactor: interactor)
            return interactor
        }
   
        init() {}
    }
}

extension EZUIPack {
    public static func make(
        interactor maker: @autoclosure () -> I = I(nibName: nil, bundle: nil)
    ) -> I {
        EZPackMaker.make(packType: Self.self, interactor: maker)
    }
    
    public static func make(
        interactor maker: () -> I
    ) -> I {
        EZPackMaker.make(packType: Self.self, interactor: maker)
    }
}

#endif
