//
//  EZUINavigationControllerDelegate.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

import Foundation
#if canImport(UIKit) && !os(watchOS)
import UIKit

open class EZUINavigationControllerDelegate: NSObject, UINavigationControllerDelegate {
    public weak var delegate: UINavigationControllerDelegate?
    
    public var animation: (any UIViewControllerAnimatedTransitioning)?
    public var interactive: UIPercentDrivenInteractiveTransition?
    
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
