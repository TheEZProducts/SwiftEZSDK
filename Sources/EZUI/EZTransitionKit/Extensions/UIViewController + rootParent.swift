//
//  UIViewController + rootParent.swift
//  EZSDK
//
//  Created by Александр Сенин on 24.01.2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController{
    /// The root parent view controller in the hierarchy.
    ///
    /// Recursively searches up the parent chain to find the topmost view controller
    /// that has no parent. Returns `self` if this view controller has no parent.
    ///
    /// ### Example
    /// ```swift
    /// let root = viewController.rootParent
    /// // root is the topmost view controller in the hierarchy
    /// ```
    public var rootParent: UIViewController {
        parent?.rootParent ?? self
    }
}
#endif
