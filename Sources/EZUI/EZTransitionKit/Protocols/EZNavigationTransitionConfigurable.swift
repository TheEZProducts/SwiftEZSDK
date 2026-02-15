//
//  EZNavigationTransitionConfigurable.swift
//  EZTransitionKit
//
//  Created by Александр Сенин on 14.02.2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

@MainActor
public protocol EZNavigationTransitionConfigurable: UINavigationController {
    var defaultChildrenPushTransitionAnimation: (any UIViewControllerAnimatedTransitioning)? { get }
    var defaultChildrenPopTransitionAnimation: (any UIViewControllerAnimatedTransitioning)? { get }
}
#endif
