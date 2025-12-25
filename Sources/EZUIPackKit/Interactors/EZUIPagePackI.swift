//
//  EZUIPagePack.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

public protocol EZUIPagePackProtocol: UIPageViewController, EZUIPackProtocol {}

extension EZUIPack where I: EZUIPagePackI {
    public static func make() -> I {
        make(.init())
    }
    
    public static func make(_ mediator: M) -> I {
        make(
            transitionStyle: .scroll,
            navigationOrientation: .vertical,
            mediator: mediator
        )
    }
    
    public static func make(
        transitionStyle style: UIPageViewController.TransitionStyle,
        navigationOrientation: UIPageViewController.NavigationOrientation,
        options: [UIPageViewController.OptionsKey : Any]? = nil,
        mediator: M
    ) -> I {
        make(
            mediator,
            customData: (
                transitionStyle: style,
                navigationOrientation: navigationOrientation,
                options: options
            )
        )
    }
}


public typealias EZUIPagePackI = EZUIPagePackInteractor & EZUIPagePackProtocol

open class EZUIPagePackInteractor: UIPageViewController, EZUIPackBaseInteractorProtocol {
    public var pack: any EZUIPackProtocol
    
#if !os(tvOS)
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        delegate?.pageViewControllerSupportedInterfaceOrientations?(self) ??
        pack.view.supportedInterfaceOrientations ??
        super.supportedInterfaceOrientations
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        delegate?.pageViewControllerPreferredInterfaceOrientationForPresentation?(self) ??
        pack.view.preferredInterfaceOrientationForPresentation ??
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
    
    public required init(
        pack: some EZUIPackProtocol,
        customData: (
            transitionStyle: UIPageViewController.TransitionStyle,
            navigationOrientation: UIPageViewController.NavigationOrientation,
            options: [UIPageViewController.OptionsKey : Any]?
        )
    ) {
        self.pack = pack
        super.init(
            transitionStyle: customData.transitionStyle,
            navigationOrientation: customData.navigationOrientation,
            options: customData.options
        )
    }
    
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
