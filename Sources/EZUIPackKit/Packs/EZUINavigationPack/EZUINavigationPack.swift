//
//  EZUINavigationPack.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

import Foundation
#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

extension EZUIPackBridge{
    public var navigationPack: (any EZUINavigationPackProtocol)? {
        pack as? any EZUINavigationPackProtocol
    }
}

public protocol EZUINavigationPackProtocol: UINavigationController, EZUIPackProtocol{
    var defaultChildrenPushTransitionAnimation: UIViewControllerAnimatedTransitioning? { get set }
    var defaultChildrenPopTransitionAnimation: UIViewControllerAnimatedTransitioning? { get set }
}

extension UINavigationController{
    @discardableResult
    public func wrappDelegateForChildTransition<Result>(
        animation: UIViewControllerAnimatedTransitioning? = nil,
        interactive: Bool = false,
        action: (UIPercentDrivenInteractiveTransition?) -> (Result)
    ) -> Result{
        if let delegate = delegate as? EZUINavigationControllerDelegate {
            return action(delegate.interactive)
        }else{
            let wrapper = EZUINavigationControllerDelegate(
                delegate: delegate,
                animation: animation,
                interactive: interactive ? UIPercentDrivenInteractiveTransition() : nil
            )
            delegate = wrapper
            defer { delegate = wrapper.delegate }
            return action(wrapper.interactive)
        }
    }
}

open class EZUINavigationPack<
    I: EZUIPackInteractorProtocol,
    M: EZUIPackMediatorProtocol,
    V: EZUIPackViewProtocol
>: UINavigationController, EZUINavigationPackProtocol where I.Mediator == M, V.Mediator == M{
    public var defaultChildrenPushTransitionAnimation: (any UIViewControllerAnimatedTransitioning)?
    public var defaultChildrenPopTransitionAnimation: (any UIViewControllerAnimatedTransitioning)?
    
    public var storage: EZUIPackStorage<I, M, V>
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        delegate?.navigationControllerSupportedInterfaceOrientations?(self) ??
        storage.view.supportedInterfaceOrientations ??
        topViewController?.supportedInterfaceOrientations ??
        super.supportedInterfaceOrientations
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        delegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(self) ??
        storage.view.preferredInterfaceOrientationForPresentation ??
        topViewController?.preferredInterfaceOrientationForPresentation ??
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
    
    public init(mediator: M) {
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
        let oldView: UIView = view
        view = storage.loadView()
        view.frame = oldView.frame
        view.addSubview(oldView)
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
    
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        wrappDelegateForChildTransition {_ in 
            super.pushViewController(viewController, animated: animated)
        }
    }
    
    @discardableResult
    open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        wrappDelegateForChildTransition {_ in
             super.popToViewController(viewController, animated: animated)
        }
    }
    
    @discardableResult
    open override func popViewController(animated: Bool) -> UIViewController? {
        wrappDelegateForChildTransition {_ in
            super.popViewController(animated: animated)
        }
    }
    
    @discardableResult
    open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        wrappDelegateForChildTransition {_ in
            super.popToRootViewController(animated: animated)
        }
    }
    
    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        wrappDelegateForChildTransition {_ in 
            super.setViewControllers(viewControllers, animated: animated)
        }
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
