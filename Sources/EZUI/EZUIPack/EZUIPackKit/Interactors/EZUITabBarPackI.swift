//
//  EZUITabBarPack.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Protocol for tab bar controller interactors in the IMV architecture.
///
/// Extends `EZUIPackInteractorProtocol` with tab bar-specific transition animations.
/// Use this when creating packs that use `UITabBarController` as their interactor.
///
/// ### Example
/// ```swift
/// class MainTabBarPackI: EZUITabBarPackI {
///     let access = MainTabBarPackM.accessI
///     
///     var defaultChildrenTransitionAnimation: UIViewControllerAnimatedTransitioning?
///     
///     func makeInput() -> Mediator.InputI { self }
/// }
/// ```
public protocol EZUITabBarInteractorProtocol: UITabBarController, EZUIPackInteractorProtocol, EZTabBarTransitionConfigurable {
    /// Default transition animation for switching between tabs.
    ///
    /// Set this to provide a custom animation when switching tabs.
    /// If `nil`, uses the default UIKit tab switching animation.
    var defaultChildrenTransitionAnimation: UIViewControllerAnimatedTransitioning? { get set }
}

/// The primary type for creating tab bar controller interactors in the IMV architecture.
///
/// `EZUITabBarPackI` is a type alias that combines `EZUITabBarPackInteractor` and
/// `EZUITabBarInteractorProtocol`, providing everything you need to create a tab bar-based
/// pack. This is the **recommended base type** for all tab bar controller implementations.
///
/// A tab bar interactor created with this type:
/// - Integrates `UITabBarController` with the IMV pattern
/// - Supports custom tab switching transition animations
/// - Automatically handles delegate wrapping for child transitions
/// - Provides all standard `EZUIPackI` functionality
///
/// ## Example: Complete tab bar interactor implementation
///
/// ```swift
/// class MainTabBarPackI: EZUITabBarPackI {
///     let access = MainTabBarPackM.accessI
///     
///     func makeInput() -> Mediator.InputI { self }
///     
///     func start() {
///         // Set up tabs
///         let homeVC = HomePack.make()
///         let profileVC = ProfilePack.make()
///         let settingsVC = SettingsPack.make()
///         viewControllers = [homeVC, profileVC, settingsVC]
///     }
/// }
/// ```
///
/// ## Custom Transitions
///
/// Set `defaultChildrenTransitionAnimation` to provide a custom animation for tab switching.
/// This animation will be used automatically when switching between tabs.
///
/// - Note: Always use `EZUITabBarPackI` as your base type for tab bar-based packs.
///   It provides proper integration with UIKit's tab bar controller and the IMV architecture.
public typealias EZUITabBarPackI = EZUITabBarPackInteractor & EZUITabBarInteractorProtocol

/// Base class for tab bar controller interactors in the IMV architecture.
///
/// This class integrates `UITabBarController` with the IMV pattern, providing:
/// - Automatic pack lifecycle integration
/// - Custom transition animations for tab switching
/// - Proper delegate wrapping for child transitions
///
/// ### Example
/// ```swift
/// class MainTabBarPackI: EZUITabBarPackInteractor, EZUITabBarInteractorProtocol {
///     let access = MainTabBarPackM.accessI
///     
///     func makeInput() -> Mediator.InputI { self }
/// }
/// ```
open class EZUITabBarPackInteractor: UITabBarController, EZUIPackBaseInteractorProtocol {
    /// The pack that manages this interactor.
    ///
    /// Automatically retrieved during initialization via `EZPackMaker.getPack()`.
    public var pack: (any EZUIPackProtocol) = EZPackMaker.getPack()
    
    /// Default transition animation for switching between tabs.
    ///
    /// Set this to provide a custom animation when switching tabs.
    /// If `nil`, uses the default UIKit tab switching animation.
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
}
#endif
