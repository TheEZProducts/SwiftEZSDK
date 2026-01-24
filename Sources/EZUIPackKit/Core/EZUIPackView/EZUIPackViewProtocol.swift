//
//  EZUIPackV.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

#if canImport(SwiftUI)
import SwiftUI
#endif

/// Protocol for views in the IMV architecture that integrate with UIKit lifecycle.
///
/// Extends `EZViewProtocol` with UIKit-specific lifecycle methods and appearance customization.
/// Views implementing this protocol can customize:
/// - Interface orientations
/// - Status bar appearance
/// - UIKit view controller lifecycle callbacks
///
/// ### Example: iOS view implementation
/// ```swift
/// class ProfileIOSV: EZUIPackV {
///     let access = ProfilePackM.accessV
///     
///     func makeContext() -> Mediator.ContextV {
///         .init(actions: self)
///     }
///     
///     func create() {
///         backgroundColor = .systemBackground
///         setupSubviews()
///     }
///     
///     func willOpen() {
///         // Prepare for appearance
///     }
///     
///     func animateOpen() {
///         // Animate appearance
///         UIView.animate(withDuration: 0.3) {
///             self.alpha = 1.0
///         }
///     }
/// }
/// ```
public protocol EZUIPackViewProtocol<Mediator>: EZViewProtocol {
#if !os(tvOS) && !os(watchOS)
    /// The interface orientations supported by this view.
    ///
    /// Return `nil` to use the default behavior. Override to restrict orientations.
    var supportedInterfaceOrientations: UIInterfaceOrientationMask? { get }
    
    /// The preferred interface orientation for presentation.
    ///
    /// Return `nil` to use the default behavior. Override to specify a preferred orientation.
    var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation? { get }
    
    /// The preferred status bar style.
    ///
    /// Return `nil` to use the default behavior. Override to customize status bar appearance.
    var preferredStatusBarStyle: UIStatusBarStyle? { get }
    
    /// Whether the status bar should be hidden.
    ///
    /// Return `nil` to use the default behavior. Override to hide/show the status bar.
    var prefersStatusBarHidden: Bool? { get }
    
    /// The preferred status bar update animation.
    ///
    /// Return `nil` to use the default behavior. Override to customize the animation.
    var preferredStatusBarUpdateAnimation: UIStatusBarAnimation? { get }
#endif
    
#if !os(watchOS)
    /// Returns the view that will be displayed.
    ///
    /// This method should return a configured `UIView` (or `NSView` on macOS) ready for display.
    /// For `EZUIPackUIViewProtocol` views, this typically returns `self`.
    ///
    /// - Returns: A configured view ready for display.
    func getView() -> EZView
#endif
    
    /// Called after the mediator is created and connected, but before `create()`.
    ///
    /// Use this to perform setup that requires mediator access.
    func didInitialize()
    
    /// Called when the pack is about to become visible, before animations start.
    ///
    /// Use this to prepare the view before it appears.
    func willOpen()
    
    /// Called to animate the view's appearance.
    ///
    /// Implement this to provide custom appearance animations.
    func animateOpen()
    
    /// Called after the pack has fully appeared and animations completed.
    ///
    /// Use this to perform actions that should happen when the view is visible.
    func didOpen()
    
    /// Called after the view's layout has completed for the first time.
    ///
    /// Use this to perform layout-dependent operations.
    func didInstall()
    
    /// Called when the pack is about to disappear, before animations start.
    ///
    /// Use this to prepare the view before it disappears.
    func willClose()
    
    /// Called to animate the view's disappearance.
    ///
    /// Implement this to provide custom disappearance animations.
    func animateClose()
    
    /// Called after the pack has fully disappeared and animations completed.
    ///
    /// Use this to clean up resources.
    func didClose()
    
    /// Called when the view has been loaded.
    ///
    /// Equivalent to `UIViewController.viewDidLoad()`. Use this for initial setup.
    func viewDidLoad()
    
    /// Called when the view is about to appear.
    ///
    /// Equivalent to `UIViewController.viewWillAppear(_:)`.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    func viewWillAppear(_ animated: Bool)
    
    /// Called during the appearance transition (iOS 13.0+).
    ///
    /// Equivalent to `UIViewController.viewIsAppearing(_:)`.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    @available(iOS 13.0, tvOS 13.0, *)
    func viewIsAppearing(_ animated: Bool)
    
    /// Called when the view has fully appeared.
    ///
    /// Equivalent to `UIViewController.viewDidAppear(_:)`.
    ///
    /// - Parameter animated: Whether the appearance was animated.
    func viewDidAppear(_ animated: Bool)
    
    /// Called when the view is about to disappear.
    ///
    /// Equivalent to `UIViewController.viewWillDisappear(_:)`.
    ///
    /// - Parameter animated: Whether the disappearance is animated.
    func viewWillDisappear(_ animated: Bool)
    
    /// Called when the view has fully disappeared.
    ///
    /// Equivalent to `UIViewController.viewDidDisappear(_:)`.
    ///
    /// - Parameter animated: Whether the disappearance was animated.
    func viewDidDisappear(_ animated: Bool)
}

extension EZUIPackViewProtocol {
#if !os(tvOS) && !os(watchOS)
    /// Default implementation: returns `nil` to use default behavior.
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask? { nil }
    
    /// Default implementation: returns `nil` to use default behavior.
    public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation? { nil }
    
    /// Default implementation: returns `nil` to use default behavior.
    public var preferredStatusBarStyle: UIStatusBarStyle? { nil }
    
    /// Default implementation: returns `nil` to use default behavior.
    public var prefersStatusBarHidden: Bool? { nil }
    
    /// Default implementation: returns `nil` to use default behavior.
    public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation? { nil }
#endif
    
    /// Default implementation: no-op.
    public func didInitialize(){}
    
    /// Default implementation: no-op.
    public func willOpen(){}
    
    /// Default implementation: no-op.
    public func animateOpen(){}
    
    /// Default implementation: no-op.
    public func didOpen(){}
    
    /// Default implementation: no-op.
    public func didInstall(){}
    
    /// Default implementation: no-op.
    public func willClose(){}
    
    /// Default implementation: no-op.
    public func animateClose(){}
    
    /// Default implementation: no-op.
    public func didClose(){}
    
    /// Default implementation: no-op.
    public func viewDidLoad(){}
    
    /// Default implementation: no-op.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    public func viewWillAppear(_ animated: Bool){}
    
    /// Default implementation: no-op.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    @available(iOS 13.0, tvOS 13.0, *)
    public func viewIsAppearing(_ animated: Bool){}
    
    /// Default implementation: no-op.
    ///
    /// - Parameter animated: Whether the appearance was animated.
    public func viewDidAppear(_ animated: Bool){}
    
    /// Default implementation: no-op.
    ///
    /// - Parameter animated: Whether the disappearance is animated.
    public func viewWillDisappear(_ animated: Bool){}
    
    /// Default implementation: no-op.
    ///
    /// - Parameter animated: Whether the disappearance was animated.
    public func viewDidDisappear(_ animated: Bool){}
}

#endif
