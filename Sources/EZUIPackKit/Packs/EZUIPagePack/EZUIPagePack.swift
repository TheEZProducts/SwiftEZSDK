//
//  EZUIPagePack.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

extension EZUIPackBridge{
    public var pagePack: (any EZUIPagePackProtocol)? {
        pack as? any EZUIPagePackProtocol
    }
}

public protocol EZUIPagePackProtocol: UIPageViewController, EZUIPackProtocol{}

extension UIViewController{
    public var pageController: UIPageViewController?{
        (parent as? UIPageViewController) ?? parent?.pageController
    }
}

open class EZUIPagePack<
    I: EZUIPackInteractorProtocol,
    M: EZUIPackMediatorProtocol,
    V: EZUIPackViewProtocol
>: UIPageViewController, EZUIPagePackProtocol where I.Mediator == M, V.Mediator == M{
    public var defaultChildrenTransitionAnimation: (any UIViewControllerAnimatedTransitioning)?
    
    public var storage: EZUIPackStorage<I, M, V>
    
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        delegate?.pageViewControllerSupportedInterfaceOrientations?(self) ??
        storage.view.supportedInterfaceOrientations ??
        super.supportedInterfaceOrientations
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        delegate?.pageViewControllerPreferredInterfaceOrientationForPresentation?(self) ??
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
        super.init(
            transitionStyle: .scroll,
            navigationOrientation: .horizontal,
            options: nil
        )
        storage.setupPack(pack: self)
    }
    
    public init(
        transitionStyle style: UIPageViewController.TransitionStyle,
        navigationOrientation: UIPageViewController.NavigationOrientation,
        options: [UIPageViewController.OptionsKey : Any]? = nil,
        mediator: M
    ) {
        storage = .init(mediator: mediator)
        super.init(
            transitionStyle: style,
            navigationOrientation: navigationOrientation,
            options: options
        )
        storage.setupPack(pack: self)
    }
    
    public convenience override init(
        transitionStyle style: UIPageViewController.TransitionStyle,
        navigationOrientation: UIPageViewController.NavigationOrientation,
        options: [UIPageViewController.OptionsKey : Any]? = nil
    ) {
        self.init(
            transitionStyle: style,
            navigationOrientation: navigationOrientation,
            options: options,
            mediator: .init()
        )
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
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
