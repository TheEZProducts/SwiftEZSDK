//
//  UIViewController + sourceViewController.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    /// The source view controller that presented or contains this view controller.
    ///
    /// Returns the parent view controller if this is a child, or the presenting view controller
    /// if this was presented modally. Returns `nil` if this is a root view controller.
    public var ezSourceViewController: UIViewController? {
        parent ?? presentingViewController
    }
    
    /// The first transition controller found in the view controller hierarchy.
    ///
    /// Searches this view controller and its parents/presenters for a transition controller.
    /// Returns `nil` if no transition controller is found.
    public var ezFirstTransitionController: EZTransitionControllerProtocol? {
        (self as? any EZTransitionControlledProtocol)?.transitionController ??
        ezSourceViewController?.ezFirstTransitionController
    }
}
#endif
