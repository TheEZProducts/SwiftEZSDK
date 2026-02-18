//
//  EZUINavigationPackI.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Protocol for navigation controller interactors in the IMV architecture.
///
/// Extends `EZUIPackInteractorProtocol` with navigation-specific transition animations.
/// Use this when creating packs that use `UINavigationController` as their interactor.
///
/// ### Example
/// ```swift
/// class MainNavigationPackI: EZUINavigationPackI {
///     let access = MainNavigationPackM.accessI
///     
///     func makeInput() -> Mediator.InputI { self }
/// }
/// ```
public protocol EZUINavigationInteractorProtocol: UINavigationController, EZUIPackInteractorProtocol, EZNavigationTransitionConfigurable {
    /// Default transition animation for pushing child view controllers.
    ///
    /// Set this to provide a custom animation when pushing view controllers onto the navigation stack.
    /// If `nil`, uses the default UIKit push animation.
    var defaultChildrenPushTransitionAnimation: UIViewControllerAnimatedTransitioning? { get set }
    
    /// Default transition animation for popping child view controllers.
    ///
    /// Set this to provide a custom animation when popping view controllers from the navigation stack.
    /// If `nil`, uses the default UIKit pop animation.
    var defaultChildrenPopTransitionAnimation: UIViewControllerAnimatedTransitioning? { get set }
}

/// The primary type for creating navigation controller interactors in the IMV architecture.
///
/// `EZUINavigationPackI` is a type alias that combines `EZUINavigationPackInteractor` and
/// `EZUINavigationInteractorProtocol`, providing everything you need to create a navigation-based
/// pack. This is the **recommended base type** for all navigation controller implementations.
///
/// A navigation interactor created with this type:
/// - Integrates `UINavigationController` with the IMV pattern
/// - Supports custom push/pop transition animations
/// - Automatically handles delegate wrapping for child transitions
/// - Provides all standard `EZUIPackI` functionality
///
/// ## Example: Complete navigation interactor implementation
///
/// ```swift
/// class MainNavigationPackI: EZUINavigationPackI {
///     let access = MainNavigationPackM.accessI
///     
///     var defaultChildrenPushTransitionAnimation: UIViewControllerAnimatedTransitioning?
///     var defaultChildrenPopTransitionAnimation: UIViewControllerAnimatedTransitioning?
///     
///     func makeInput() -> Mediator.InputI { self }
///     
///     func start() {
///         // Set up initial navigation stack
///         let homeVC = HomePack.make()
///         setViewControllers([homeVC], animated: false)
///     }
/// }
/// ```
///
/// ## Custom Transitions
///
/// Set `defaultChildrenPushTransitionAnimation` and `defaultChildrenPopTransitionAnimation` to
/// provide custom animations for push/pop operations. These animations will be used automatically
/// when pushing or popping view controllers.
///
/// - Note: Always use `EZUINavigationPackI` as your base type for navigation-based packs.
///   It provides proper integration with UIKit's navigation controller and the IMV architecture.
public typealias EZUINavigationPackI = EZUINavigationPackInteractor & EZUINavigationInteractorProtocol

/// Base class for navigation controller interactors in the IMV architecture.
///
/// This class integrates `UINavigationController` with the IMV pattern, providing:
/// - Automatic pack lifecycle integration
/// - Custom transition animations for push/pop operations
/// - Proper delegate wrapping for child transitions
///
/// ### Example
/// ```swift
/// class MainNavigationPackI: EZUINavigationPackInteractor, EZUINavigationInteractorProtocol {
///     let access = MainNavigationPackM.accessI
///     
///     func makeInput() -> Mediator.InputI { self }
/// }
/// ```
open class EZUINavigationPackInteractor: UINavigationController, EZUIPackBaseInteractorProtocol {
    /// The pack that manages this interactor.
    ///
    /// Automatically retrieved during initialization via `EZPackMaker.getPack()`.
    public var pack: (any EZUIPackProtocol) = EZPackMaker.getPack()
    
    /// Default transition animation for pushing child view controllers.
    ///
    /// Set this to provide a custom animation when pushing view controllers onto the navigation stack.
    /// If `nil`, uses the default UIKit push animation.
    public var defaultChildrenPushTransitionAnimation: (any UIViewControllerAnimatedTransitioning)?
    
    /// Default transition animation for popping child view controllers.
    ///
    /// Set this to provide a custom animation when popping view controllers from the navigation stack.
    /// If `nil`, uses the default UIKit pop animation.
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
    
    /// Pushes a view controller onto the navigation stack with proper transition handling.
    ///
    /// Wraps the delegate to handle child transitions correctly.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to push.
    ///   - animated: Whether the transition should be animated.
    open override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        wrappDelegateForChildTransition {_ in 
            super.pushViewController(viewController, animated: animated)
        }
    }
    
    /// Pops view controllers until the specified view controller is at the top of the stack.
    ///
    /// Wraps the delegate to handle child transitions correctly.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to pop to.
    ///   - animated: Whether the transition should be animated.
    /// - Returns: The view controllers that were popped, or `nil` if the view controller wasn't found.
    @discardableResult
    open override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        wrappDelegateForChildTransition {_ in
             super.popToViewController(viewController, animated: animated)
        }
    }
    
    /// Pops the top view controller from the navigation stack.
    ///
    /// Wraps the delegate to handle child transitions correctly.
    ///
    /// - Parameter animated: Whether the transition should be animated.
    /// - Returns: The view controller that was popped, or `nil` if there was only one view controller.
    @discardableResult
    open override func popViewController(animated: Bool) -> UIViewController? {
        wrappDelegateForChildTransition {_ in
            super.popViewController(animated: animated)
        }
    }
    
    /// Pops all view controllers except the root view controller.
    ///
    /// Wraps the delegate to handle child transitions correctly.
    ///
    /// - Parameter animated: Whether the transition should be animated.
    /// - Returns: The view controllers that were popped, or `nil` if there was only one view controller.
    @discardableResult
    open override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        wrappDelegateForChildTransition {_ in
            super.popToRootViewController(animated: animated)
        }
    }
    
    /// Sets the view controllers currently on the navigation stack.
    ///
    /// Wraps the delegate to handle child transitions correctly.
    ///
    /// - Parameters:
    ///   - viewControllers: The view controllers to set.
    ///   - animated: Whether the transition should be animated.
    open override func setViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        wrappDelegateForChildTransition {_ in 
            super.setViewControllers(viewControllers, animated: animated)
        }
    }
}

#endif
