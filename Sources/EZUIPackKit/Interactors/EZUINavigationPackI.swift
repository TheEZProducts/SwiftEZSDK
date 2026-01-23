//
//  EZUINavigationPack.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

public protocol EZUINavigationInteractorProtocol: UINavigationController, EZUIPackInteractorProtocol {
    var defaultChildrenPushTransitionAnimation: UIViewControllerAnimatedTransitioning? { get set }
    var defaultChildrenPopTransitionAnimation: UIViewControllerAnimatedTransitioning? { get set }
}

public typealias EZUINavigationPackI = EZUINavigationPackInteractor & EZUINavigationInteractorProtocol

open class EZUINavigationPackInteractor: UINavigationController, EZUIPackBaseInteractorProtocol {
    public var pack: (any EZUIPackProtocol) = EZPackMaker.getPack()
    
    public var defaultChildrenPushTransitionAnimation: (any UIViewControllerAnimatedTransitioning)?
    public var defaultChildrenPopTransitionAnimation: (any UIViewControllerAnimatedTransitioning)?
    
#if !os(tvOS)
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        delegate?.navigationControllerSupportedInterfaceOrientations?(self) ??
        pack.view.supportedInterfaceOrientations ??
        topViewController?.supportedInterfaceOrientations ??
        super.supportedInterfaceOrientations
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        delegate?.navigationControllerPreferredInterfaceOrientationForPresentation?(self) ??
        pack.view.preferredInterfaceOrientationForPresentation ??
        topViewController?.preferredInterfaceOrientationForPresentation ??
        super.preferredInterfaceOrientationForPresentation
    }
    
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "Has no effect on visionOS")
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        pack.view.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "Has no effect on visionOS")
    open override var prefersStatusBarHidden: Bool {
        pack.view.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
    
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "Has no effect on visionOS")
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        pack.view.preferredStatusBarUpdateAnimation ?? super.preferredStatusBarUpdateAnimation
    }
#endif
    
    open override func loadView() {
        super.loadView()
        let oldView: UIView = view
        view = pack.loadView(frame: view.frame)
        view.addSubview(oldView)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        pack.viewDidLoad()
    }
    
    open override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        pack.didMove(toParent: parent)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pack.viewWillAppear(animated)
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    open override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        pack.viewIsAppearing(animated)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pack.viewDidLayoutSubviews()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pack.viewDidAppear(animated)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pack.viewWillDisappear(animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pack.viewDidDisappear(animated)
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
}

#endif
