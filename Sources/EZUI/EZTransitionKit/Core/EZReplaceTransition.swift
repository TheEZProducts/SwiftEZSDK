//
//  EZReplaceTransition.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension EZTransition<UIViewController>{
    /// Creates a transition that replaces the current view controller.
    ///
    /// Automatically determines whether to use navigation or tab bar replacement based on
    /// the controller's parent.
    ///
    /// - Parameter controller: The view controller to replace with.
    /// - Returns: A replace transition instance (navigation or tab bar, as appropriate).
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.replace(newVC)
    ///     .animate()
    ///     .transit()
    /// ```
    public func replace(_ controller: UIViewController) -> any EZReplaceTransitionProtocol<EZChildTransitionContext> {
        if controller.parent is UINavigationController {
            return navigationReplace(controller)
        }else {
            return tabBarReplace(controller)
        }
    }
}

/// Protocol for transitions that replace view controllers.
///
/// Transitions conforming to this protocol replace the current view controller with another,
/// either in a navigation stack or tab bar.
public protocol EZReplaceTransitionProtocol<Context>: EZTransitionProtocol{}
#endif
