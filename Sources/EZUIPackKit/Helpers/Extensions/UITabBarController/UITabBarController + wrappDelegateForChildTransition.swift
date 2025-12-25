//
//  UITabBarController + wrappDelegateForChildTransition.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UITabBarController {
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
