//
//  UIViewControllerTransitioning.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

open class EZUIViewControllerTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    public weak var delegate: UIViewControllerTransitioningDelegate?
    
    public var animation: UIViewControllerAnimatedTransitioning?
    public var interactive: UIPercentDrivenInteractiveTransition?
    
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
