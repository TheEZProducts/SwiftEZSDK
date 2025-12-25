//
//  UIViewController + firstTransitionCoordinator.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    @available(iOS 7.0, macCatalyst 13.1, *)
    public var firstTransitionCoordinator: (any UIViewControllerTransitionCoordinator)? {
        transitionCoordinator ?? parent?.firstTransitionCoordinator
    }
}

#endif
