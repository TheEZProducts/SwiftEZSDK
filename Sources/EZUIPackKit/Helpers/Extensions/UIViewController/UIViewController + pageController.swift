//
//  UIViewController + pageController.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    public var pageController: UIPageViewController? {
        (parent as? UIPageViewController) ?? parent?.pageController
    }
}

#endif
