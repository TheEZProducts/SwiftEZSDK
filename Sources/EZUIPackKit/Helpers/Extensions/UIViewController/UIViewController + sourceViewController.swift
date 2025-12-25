//
//  UIViewController + sourceViewController.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    public var ezSourceViewController: UIViewController? {
        parent ?? presentingViewController
    }
    
    public var ezFirstTransitionController: EZTransitionControllerProtocol? {
        (self as? any EZTransitionControlledProtocol)?.transitionController ??
        ezSourceViewController?.ezFirstTransitionController
    }
}
#endif
