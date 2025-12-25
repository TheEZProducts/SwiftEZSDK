//
//  EZUITabBarPack.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

public protocol EZUITabBarInteractorProtocol: UITabBarController, EZUIPackInteractorProtocol {
    var defaultChildrenTransitionAnimation: UIViewControllerAnimatedTransitioning? { get set }
}

public typealias EZUITabBarPackI = EZUITabBarPackInteractor & EZUITabBarInteractorProtocol

open class EZUITabBarPackInteractor: UITabBarController, EZUIPackBaseInteractorProtocol {
    public var pack: (any EZUIPackProtocol)
    
    public var defaultChildrenTransitionAnimation: (any UIViewControllerAnimatedTransitioning)?
    
#if !os(tvOS) && !os(visionOS)
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        delegate?.tabBarControllerSupportedInterfaceOrientations?(self) ??
        pack.view.supportedInterfaceOrientations ??
        selectedViewController?.supportedInterfaceOrientations ??
        super.supportedInterfaceOrientations
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        delegate?.tabBarControllerPreferredInterfaceOrientationForPresentation?(self) ??
        pack.view.preferredInterfaceOrientationForPresentation ??
        selectedViewController?.preferredInterfaceOrientationForPresentation ??
        super.preferredInterfaceOrientationForPresentation
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        pack.view.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    open override var prefersStatusBarHidden: Bool {
        pack.view.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
    
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        pack.view.preferredStatusBarUpdateAnimation ?? super.preferredStatusBarUpdateAnimation
    }
#endif
    
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
    
    public required init(pack: some EZUIPackProtocol, customData: ()) {
        self.pack = pack
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
