//
//  EZUIPack.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

@MainActor
public protocol EZUIPackProtocol: UIViewController, EZTransitionControlledProtocol, EZSharingProtocol{
    associatedtype Controller: EZUIPackInteractorProtocol where Controller.Mediator == Mediator
    associatedtype Mediator: EZUIPackMediatorProtocol
    associatedtype View: EZUIPackViewProtocol where View.Mediator == Mediator
    
    var storage: EZUIPackStorage<Controller, Mediator, View> { get set }
    
    func didInitialize()
    
    init(mediator: Mediator)
}

extension EZUIPackProtocol{
    public var transitionController: EZTransitionControllerProtocol? {
        _read{ yield storage.transitionController }
        _modify { yield &storage.transitionController }
    }
    
    public var shared: EZSharedStorage? {
        _read{ yield storage.mediator.shared }
    }
}

extension UIViewController {
    public var sourceViewController: UIViewController? {
        parent ?? presentingViewController
    }
    
    public var firstTransitionController: EZTransitionControllerProtocol? {
        (self as? any EZTransitionControlledProtocol)?.transitionController ??
        sourceViewController?.firstTransitionController
    }
}

extension UIViewController {
    public var transit: EZTransition<UIViewController> { EZTransition(self) }
}

extension UIViewController {
    public var parentShered: EZSharedStorage {
        checkShared(sourceViewController) ?? .init()
    }
    
    private func checkShared(_ vc: UIViewController?) -> EZSharedStorage?{
        guard let vc = vc else {return nil}
        var shared = (vc as? EZSharingProtocol)?.shared
        if let superShared = checkShared(vc.sourceViewController){ shared = superShared + shared }
        return shared
    }
}

@MainActor
open class EZUIPackBridge{
    public weak var pack: (any EZUIPackProtocol)?
    
    public init(pack: (any EZUIPackProtocol)? = nil) {
        self.pack = pack
    }
    
    open var transit: EZTransition<UIViewController> { EZTransition(pack ?? UIViewController()) }
}

open class UIViewControllerTransitioning: NSObject, UIViewControllerTransitioningDelegate{
    public weak var delegate: UIViewControllerTransitioningDelegate?
    
    public var animation: UIViewControllerAnimatedTransitioning?
    public var interactive: UIPercentDrivenInteractiveTransition?
    
    public init(
        delegate: UIViewControllerTransitioningDelegate?,
        animation: UIViewControllerAnimatedTransitioning? = nil,
        interactive: UIPercentDrivenInteractiveTransition? = nil
    ) {
        self.delegate = delegate
        self.animation = animation
        self.interactive = interactive
    }
    
    open func animationController(
        forPresented presented: UIViewController,
        presenting: UIViewController,
        source: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)?{
        animation ?? delegate?.animationController?(
            forPresented: presented,
            presenting: presenting,
            source: source
        )
    }
    
    open func animationController(
        forDismissed dismissed: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)?{
        animation ?? delegate?.animationController?(
            forDismissed: dismissed
        )
    }

    open func interactionControllerForPresentation(
        using animator: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)?{
        interactive ?? delegate?.interactionControllerForPresentation?(using: animator)
    }

    open func interactionControllerForDismissal(
        using animator: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)?{
        interactive ?? delegate?.interactionControllerForDismissal?(using: animator)
    }

    open func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController?{
        delegate?.presentationController?(
            forPresented: presented,
            presenting: presenting,
            source: source
        )
    }
}

extension UIViewController{
    public func wrappDelegateForTransition<Result>(
        animation: UIViewControllerAnimatedTransitioning? = nil,
        interactive: Bool = false,
        action: (UIPercentDrivenInteractiveTransition?) -> (Result)
    ) -> Result{
        if let transitioningDelegate = transitioningDelegate as? UIViewControllerTransitioning {
            return action(transitioningDelegate.interactive)
        }else{
            let wrapper = UIViewControllerTransitioning(
                delegate: transitioningDelegate,
                animation: animation,
                interactive: interactive ? UIPercentDrivenInteractiveTransition() : nil
            )
            transitioningDelegate = wrapper
            defer { transitioningDelegate = wrapper.delegate }
            return action(wrapper.interactive)
        }
    }
}

extension UIViewController {
    @available(iOS 7.0, macCatalyst 13.1, *)
    public var firstTransitionCoordinator: (any UIViewControllerTransitionCoordinator)? {
        transitionCoordinator ?? parent?.firstTransitionCoordinator
    }
}

open class EZUIPack<
    I: EZUIPackInteractorProtocol,
    M: EZUIPackMediatorProtocol,
    V: EZUIPackViewProtocol
>: UIViewController, EZUIPackProtocol where I.Mediator == M, V.Mediator == M{
    public var storage: EZUIPackStorage<I, M, V>
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        storage.view.supportedInterfaceOrientations ?? .all
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        storage.view.preferredInterfaceOrientationForPresentation ??
        super.preferredInterfaceOrientationForPresentation
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        storage.view.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    open override var prefersStatusBarHidden: Bool {
        storage.view.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
    
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        storage.view.preferredStatusBarUpdateAnimation ?? super.preferredStatusBarUpdateAnimation
    }
    
    open override var keyCommands: [UIKeyCommand]? {
        storage.interactor.keyCommands
    }
    
    required public init(mediator: M) {
        storage = .init(mediator: mediator)
        super.init(nibName: nil, bundle: nil)
        storage.setupPack(pack: self)
    }
    
    public convenience init() {
        self.init(mediator: .init())
    }
    
    open func didInitialize(){}
    
    open override func loadView() {
        super.loadView()
        let oldFrame = view.frame
        view = storage.loadView()
        view.frame = oldFrame
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        storage.viewDidLoad()
    }
    
    open override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        storage.didMove(toParent: parent)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        storage.viewWillAppear(animated)
    }
    
    @available(iOS 13.0, *)
    open override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        storage.viewIsAppearing(animated)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        storage.viewDidLayoutSubviews()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        storage.viewDidAppear(animated)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        storage.viewWillDisappear(animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        storage.viewDidDisappear(animated)
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}




