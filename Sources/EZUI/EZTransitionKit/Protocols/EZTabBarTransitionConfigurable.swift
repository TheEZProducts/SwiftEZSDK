//
//  EZTabBarTransitionConfigurable.swift
//  EZTransitionKit
//
//  Created by Александр Сенин on 14.02.2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

@MainActor
public protocol EZTabBarTransitionConfigurable: UITabBarController {
    var defaultChildrenTransitionAnimation: (any UIViewControllerAnimatedTransitioning)? { get }
}
#endif
