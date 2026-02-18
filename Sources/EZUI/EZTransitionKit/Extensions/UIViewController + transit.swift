//
//  UIViewController + transit.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    /// Provides access to transition operations for this view controller.
    ///
    /// Use this to perform custom transitions, navigation operations, and other view controller
    /// transitions in a type-safe, fluent API.
    ///
    /// ### Example
    /// ```swift
    /// viewController.ezTransit.navigationPush(otherVC).transit()
    /// ```
    public var ezTransit: EZTransition<UIViewController> { EZTransition(self) }
}

#endif
