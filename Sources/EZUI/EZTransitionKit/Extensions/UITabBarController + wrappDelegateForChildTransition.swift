//
//  UITabBarController + wrappDelegateForChildTransition.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UITabBarController {
    /// Wraps the tab bar controller's delegate to handle child transitions.
    ///
    /// Temporarily wraps the delegate to provide custom transition animations and interactive
    /// transitions for tab switching. The original delegate is restored after the action completes.
    ///
    /// - Parameters:
    ///   - animation: Optional custom transition animation. If `nil`, uses the default tab switching animation.
    ///   - interactive: Whether to enable interactive transitions.
    ///   - action: The action to perform with the wrapped delegate. Receives an interactive transition object if `interactive` is `true`.
    /// - Returns: The result of the action closure.
    ///
    /// ### Example
    /// ```swift
    /// tabBarController.wrappDelegateForChildTransition(
    ///     animation: customAnimation,
    ///     interactive: true
    /// ) { interactive in
    ///     selectedIndex = 2
    /// }
    /// ```
    @discardableResult
    public func wrappDelegateForChildTransition<Result>(
        animation: UIViewControllerAnimatedTransitioning? = nil,
        interactive: Bool = false,
        action: (UIPercentDrivenInteractiveTransition?) -> (Result)
    ) -> Result{
        if let delegate = delegate as? EZUITabBarControllerDelegate {
            return action(delegate.interactive)
        } else {
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

#endif
