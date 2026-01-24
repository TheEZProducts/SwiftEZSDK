//
//  UIViewController + firstTransitionCoordinator.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    /// The first transition coordinator found in the view controller hierarchy.
    ///
    /// Searches this view controller and its parents for a transition coordinator.
    /// Useful for coordinating animations with view controller transitions.
    ///
    /// - Returns: The transition coordinator, or `nil` if none is found.
    @available(iOS 7.0, macCatalyst 13.1, *)
    public var firstTransitionCoordinator: (any UIViewControllerTransitionCoordinator)? {
        transitionCoordinator ?? parent?.firstTransitionCoordinator
    }
}

#endif
