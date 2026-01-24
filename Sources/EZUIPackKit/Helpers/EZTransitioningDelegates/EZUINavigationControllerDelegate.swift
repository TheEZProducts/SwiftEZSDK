//
//  EZUINavigationControllerDelegate.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A wrapper delegate for `UINavigationControllerDelegate` that adds custom animations and interactive transitions.
///
/// `EZUINavigationControllerDelegate` wraps an existing navigation controller delegate and allows you to
/// inject custom animations and interactive transitions for push/pop operations without replacing the
/// original delegate's functionality. It forwards all delegate methods to the original delegate,
/// using your custom values when provided.
///
/// ### Example: Wrapping a delegate with custom animations
///
/// ```swift
/// let pushAnimation = EZOpenAnimation.ezOpen(direction: .right)
/// let popAnimation = EZCloseAnimation.ezClose(direction: .right)
/// let wrapper = EZUINavigationControllerDelegate(
///     delegate: originalDelegate,
///     animation: pushAnimation  // Note: This is used for both push and pop
/// )
/// navigationController.delegate = wrapper
/// ```
///
/// - Note: This is typically used internally by `wrappDelegateForChildTransition` extension method.
///   For separate push/pop animations, use the interactor's `defaultChildrenPushTransitionAnimation`
///   and `defaultChildrenPopTransitionAnimation` properties.
open class EZUINavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    /// The original delegate being wrapped.
    ///
    /// All delegate methods are forwarded to this delegate if custom values aren't provided.
    public weak var delegate: UINavigationControllerDelegate?
    
    /// Custom animation to use for navigation transitions.
    ///
    /// If provided, this animation will be used instead of the delegate's animation or the
    /// interactor's `defaultChildrenPushTransitionAnimation`/`defaultChildrenPopTransitionAnimation`.
    public var animation: (any UIViewControllerAnimatedTransitioning)?
    
    /// Custom interactive transition controller.
    ///
    /// If provided, this interactive transition will be used.
    /// If `nil`, the delegate's interactive transition (if any) will be used.
    public var interactive: UIPercentDrivenInteractiveTransition?
    
    /// Creates a wrapper delegate.
    ///
    /// - Parameters:
    ///   - delegate: The original delegate to wrap (can be `nil`).
    ///   - animation: Optional custom animation to use for push/pop operations.
    ///   - interactive: Optional interactive transition controller.
    public init(
        delegate: UINavigationControllerDelegate?,
        animation: (any UIViewControllerAnimatedTransitioning)? = nil,
        interactive: UIPercentDrivenInteractiveTransition? = nil
    ) {
        self.delegate = delegate
        self.animation = animation
        self.interactive = interactive
    }
    
    open func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ){
        delegate?.navigationController?(
            navigationController,
            willShow: viewController,
            animated: animated
        )
    }

    open func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ){
        delegate?.navigationController?(
            navigationController,
            didShow: viewController,
            animated: animated
        )
    }

    open func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)?{
        interactive ?? delegate?.navigationController?(
            navigationController,
            interactionControllerFor: animationController
        )
    }

    open func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)?{
        animation ?? delegate?.navigationController?(
            navigationController,
            animationControllerFor: operation,
            from: fromVC,
            to: toVC
        ) ?? {
            guard let pac = navigationController as? (any EZUINavigationInteractorProtocol) else { return nil }
            return if operation == .pop {
                pac.defaultChildrenPopTransitionAnimation
            }else{
                pac.defaultChildrenPushTransitionAnimation
            }
        }()
    }
}

#endif
