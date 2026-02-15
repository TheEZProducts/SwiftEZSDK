//
//  UIViewController + pageController.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    /// The `UIPageViewController` that contains this view controller, if any.
    ///
    /// Searches up the parent hierarchy to find a `UIPageViewController` ancestor.
    /// Returns `nil` if this view controller is not contained in a page view controller.
    public var pageController: UIPageViewController? {
        (parent as? UIPageViewController) ?? parent?.pageController
    }
}

#endif
