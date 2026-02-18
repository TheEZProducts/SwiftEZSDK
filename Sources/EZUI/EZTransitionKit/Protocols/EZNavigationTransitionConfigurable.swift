//
//  EZNavigationTransitionConfigurable.swift
//  EZTransitionKit
//
//  Created by Александр Сенин on 14.02.2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A protocol for navigation controllers that provide default transition animations for their children.
///
/// Conform your `UINavigationController` subclass to this protocol to set default push/pop
/// animations for all child view controllers. These animations are used automatically when
/// a child doesn't specify its own transition.
///
/// ### Example
/// ```swift
/// class AnimatedNavigationController: UINavigationController, EZNavigationTransitionConfigurable {
///     var defaultChildrenPushTransitionAnimation: (any UIViewControllerAnimatedTransitioning)? {
///         EZOpenAnimation()
///     }
///     var defaultChildrenPopTransitionAnimation: (any UIViewControllerAnimatedTransitioning)? {
///         EZCloseAnimation()
///     }
/// }
/// ```
@MainActor
public protocol EZNavigationTransitionConfigurable: UINavigationController {
    /// The default animation to use when pushing child view controllers.
    ///
    /// Return `nil` to use the standard UIKit push animation.
    var defaultChildrenPushTransitionAnimation: (any UIViewControllerAnimatedTransitioning)? { get }

    /// The default animation to use when popping child view controllers.
    ///
    /// Return `nil` to use the standard UIKit pop animation.
    var defaultChildrenPopTransitionAnimation: (any UIViewControllerAnimatedTransitioning)? { get }
}
#endif
