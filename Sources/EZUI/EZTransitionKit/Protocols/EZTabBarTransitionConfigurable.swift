//
//  EZTabBarTransitionConfigurable.swift
//  EZTransitionKit
//
//  Created by Александр Сенин on 14.02.2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A protocol for tab bar controllers that provide a default transition animation for tab switches.
///
/// Conform your `UITabBarController` subclass to this protocol to set a default animation
/// when switching between tabs. This animation is used automatically when
/// no per-tab transition is specified.
///
/// ### Example
/// ```swift
/// class AnimatedTabBarController: UITabBarController, EZTabBarTransitionConfigurable {
///     var defaultChildrenTransitionAnimation: (any UIViewControllerAnimatedTransitioning)? {
///         EZShiftAnimation()
///     }
/// }
/// ```
@MainActor
public protocol EZTabBarTransitionConfigurable: UITabBarController {
    /// The default animation to use when switching between tabs.
    ///
    /// Return `nil` to use the standard UIKit tab switching behavior (no animation).
    var defaultChildrenTransitionAnimation: (any UIViewControllerAnimatedTransitioning)? { get }
}
#endif
