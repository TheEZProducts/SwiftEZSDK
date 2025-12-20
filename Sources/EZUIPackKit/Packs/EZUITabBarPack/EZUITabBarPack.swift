//
//  EZUITabBarPack.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

extension EZUIPackBridge{
    public var tabBarPack: (any EZUITabBarPackProtocol)? {
        pack as? any EZUITabBarPackProtocol
    }
}

public protocol EZUITabBarPackProtocol: UITabBarController, EZUIPackProtocol{
    var defaultChildrenTransitionAnimation: UIViewControllerAnimatedTransitioning? { get set }
}

extension UITabBarController{
    @discardableResult
    public func wrappDelegateForChildTransition<Result>(
        animation: UIViewControllerAnimatedTransitioning? = nil,
        interactive: Bool = false,
        action: (UIPercentDrivenInteractiveTransition?) -> (Result)
    ) -> Result{
        if let delegate = delegate as? EZUITabBarControllerDelegate {
            return action(delegate.interactive)
        }else{
            let wrapper = EZUITabBarControllerDelegate(
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

open class EZUITabBarPack<
    I: EZUIPackInteractorProtocol,
    M: EZUIPackMediatorProtocol,
    V: EZUIPackViewProtocol
>: UITabBarController, EZUITabBarPackProtocol where I.Mediator == M, V.Mediator == M{
    public var defaultChildrenTransitionAnimation: (any UIViewControllerAnimatedTransitioning)?
    
    public var storage: EZUIPackStorage<I, M, V>
#if !os(tvOS) && !os(visionOS)
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        delegate?.tabBarControllerSupportedInterfaceOrientations?(self) ??
        storage.view.supportedInterfaceOrientations ??
        selectedViewController?.supportedInterfaceOrientations ??
        super.supportedInterfaceOrientations
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        delegate?.tabBarControllerPreferredInterfaceOrientationForPresentation?(self) ??
        storage.view.preferredInterfaceOrientationForPresentation ??
        selectedViewController?.preferredInterfaceOrientationForPresentation ??
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
#endif
    open override var keyCommands: [UIKeyCommand]? {
        storage.interactor.keyCommands
    }
    
    private var delegateWrapper: EZUITabBarControllerDelegate?
    open override var selectedViewController: UIViewController? {
        willSet{
            if delegate is EZUITabBarControllerDelegate { return }
            let wrapper = EZUITabBarControllerDelegate(delegate: delegate)
            delegateWrapper = wrapper
            delegate = wrapper
        }
        didSet{
            guard let wrapper = delegateWrapper else { return }
            delegateWrapper = nil
            delegate = wrapper.delegate
        }
    }
    
    open override var selectedIndex: Int {
        willSet{
            if delegate is EZUITabBarControllerDelegate { return }
            let wrapper = EZUITabBarControllerDelegate(delegate: delegate)
            delegateWrapper = wrapper
            delegate = wrapper
        }
        didSet{
            guard let wrapper = delegateWrapper else { return }
            delegateWrapper = nil
            delegate = wrapper.delegate
        }
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
    
    @available(iOS 13.0, tvOS 13.0, *)
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
#endif
