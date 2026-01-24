//
//  UIViewControllerTransitioning.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A wrapper delegate for `UIViewControllerTransitioningDelegate` that adds custom animations and interactive transitions.
///
/// `EZUIViewControllerTransitioningDelegate` wraps an existing transitioning delegate and allows you to
/// inject custom animations and interactive transitions without replacing the original delegate's functionality.
/// It forwards all delegate methods to the original delegate, using your custom values when provided.
///
/// ### Example: Wrapping a delegate with custom animation
///
/// ```swift
/// let customAnimation = EZOpenAnimation.ezOpen(direction: .up)
/// let wrapper = EZUIViewControllerTransitioningDelegate(
///     delegate: originalDelegate,
///     animation: customAnimation
/// )
/// viewController.transitioningDelegate = wrapper
/// ```
///
/// - Note: This is typically used internally by `wrappDelegateForTransition` extension method.
open class EZUIViewControllerTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    /// The original delegate being wrapped.
    ///
    /// All delegate methods are forwarded to this delegate if custom values aren't provided.
    public weak var delegate: UIViewControllerTransitioningDelegate?
    
    /// Custom animation to use for transitions.
    ///
    /// If provided, this animation will be used instead of the delegate's animation.
    /// If `nil`, the delegate's animation (if any) will be used.
    public var animation: UIViewControllerAnimatedTransitioning?
    
    /// Custom interactive transition controller.
    ///
    /// If provided, this interactive transition will be used.
    /// If `nil`, the delegate's interactive transition (if any) will be used.
    public var interactive: UIPercentDrivenInteractiveTransition?
    
    /// Creates a wrapper delegate.
    ///
    /// - Parameters:
    ///   - delegate: The original delegate to wrap (can be `nil`).
    ///   - animation: Optional custom animation to use.
    ///   - interactive: Optional interactive transition controller.
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

extension UIViewController {
    /// Wraps the view controller's transitioning delegate to handle custom transitions.
    ///
    /// Temporarily wraps the delegate to provide custom transition animations and interactive
    /// transitions. The original delegate is restored after the action completes.
    ///
    /// - Parameters:
    ///   - animation: Optional custom transition animation. If `nil`, uses the default animation.
    ///   - interactive: Whether to enable interactive transitions.
    ///   - action: The action to perform with the wrapped delegate. Receives an interactive transition object if `interactive` is `true`.
    /// - Returns: The result of the action closure.
    ///
    /// ### Example
    /// ```swift
    /// viewController.wrappDelegateForTransition(
    ///     animation: EZOpenAnimation.ezOpen(direction: .up),
    ///     interactive: true
    /// ) { interactive in
    ///     present(otherVC, animated: true)
    /// }
    /// ```
    public func wrappDelegateForTransition<Result>(
        animation: UIViewControllerAnimatedTransitioning? = nil,
        interactive: Bool = false,
        action: (UIPercentDrivenInteractiveTransition?) -> (Result)
    ) -> Result {
        if let transitioningDelegate = transitioningDelegate as? EZUIViewControllerTransitioningDelegate {
            return action(transitioningDelegate.interactive)
        } else {
            let wrapper = EZUIViewControllerTransitioningDelegate(
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

#endif
