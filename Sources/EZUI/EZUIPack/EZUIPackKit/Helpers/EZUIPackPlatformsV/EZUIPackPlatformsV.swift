//
//  EZUIPackPlatformsV.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

import UIKit

/// A view that automatically selects platform-specific implementations based on the current device.
///
/// `EZUIPackPlatformsV` allows you to provide different view implementations for different platforms
/// (iOS, iPadOS, macOS, tvOS, visionOS, Mac Catalyst) while using a single view type in your pack.
///
/// Override the platform-specific properties (`iOS`, `iPadOS`, `macCatalyst`, etc.) to provide
/// implementations for each platform. The appropriate view will be selected automatically at runtime.
///
/// ### Example: Multi-platform view
/// ```swift
/// class ProfilePackV: EZUIPackPlatformsV<ProfilePackM> {
///     override var iOS: (any EZUIPackViewProtocol<ProfilePackM>)? {
///         ProfileIOSV()
///     }
///     
///     override var iPadOS: (any EZUIPackViewProtocol<ProfilePackM>)? {
///         ProfileIPadOSV()
///     }
///     
///     override var macCatalyst: (any EZUIPackViewProtocol<ProfilePackM>)? {
///         ProfileMacCatalystV()
///     }
/// }
/// ```
///
/// - Note: You must provide at least one platform-specific view, otherwise initialization will crash.
open class EZUIPackPlatformsV<M: EZUIPackMediatorProtocol>: EZUIPackViewProtocol {
    public typealias Mediator = M

    /// Access to the mediator via the selected platform view.
    ///
    /// Delegates to the currently selected platform-specific view's access.
    public var access: M.AccessV { view.access }
    
    /// The currently selected platform-specific view.
    ///
    /// Set automatically by `setView()` based on the current platform.
    private(set) var view: (any EZUIPackViewProtocol<M>)!
    
    
    /// The view implementation for iPhone devices.
    ///
    /// Override this to provide a custom iOS view. Returns `nil` by default.
    open var iOS: (any EZUIPackViewProtocol<M>)? { nil }
    
    /// The view implementation for iPad devices.
    ///
    /// Override this to provide a custom iPadOS view. Returns `nil` by default.
    open var iPadOS: (any EZUIPackViewProtocol<M>)? { nil }
    
    /// The view implementation for Mac Catalyst.
    ///
    /// Override this to provide a custom Mac Catalyst view. Returns `nil` by default.
    open var macCatalyst: (any EZUIPackViewProtocol<M>)? { nil }
    
    /// The view implementation for macOS.
    ///
    /// Override this to provide a custom macOS view. Returns `nil` by default.
    open var macOS: (any EZUIPackViewProtocol<M>)? { nil }
    
    /// The view implementation for tvOS.
    ///
    /// Override this to provide a custom tvOS view. Returns `nil` by default.
    open var tvOS: (any EZUIPackViewProtocol<M>)? { nil }
    
    /// The view implementation for visionOS.
    ///
    /// Override this to provide a custom visionOS view. Returns `nil` by default.
    open var visionOS: (any EZUIPackViewProtocol<M>)? { nil }
    
#if !os(watchOS)
    /// Returns the view from the selected platform-specific implementation.
    ///
    /// Delegates to the currently selected view's `getView()` method.
    ///
    /// - Returns: A configured view ready for display.
    open func getView() -> EZView {
        view.getView()
    }
#endif
    
    /// Creates a platform-specific view and selects the appropriate implementation.
    ///
    /// Automatically calls `setView()` to select the correct platform view.
    public init() {
        setView()
    }
    
    /// Selects the appropriate platform-specific view based on the current device.
    ///
    /// This method:
    /// - Checks the current platform (iOS, macOS, tvOS, visionOS, Mac Catalyst)
    /// - For iOS, checks if it's iPhone or iPad
    /// - Selects the appropriate view from the platform-specific properties
    /// - Crashes if no view is available for the current platform
    ///
    /// Override this method if you need custom platform detection logic.
    open func setView() {
#if targetEnvironment(macCatalyst)
        view = macCatalyst
#elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone{
            view = iOS
        }else{
            view = iPadOS
        }
#elseif os(macOS)
        view = macOS
#elseif os(tvOS)
        view = tvOS
#elseif os(visionOS)
        view = visionOS
#endif
        if case .none = view {
            fatalError("No view for this platform")
        }
    }
    
#if !os(tvOS) && !os(watchOS)
    /// The interface orientations supported by this view.
    ///
    /// Delegates to the selected platform-specific view.
    open var supportedInterfaceOrientations: UIInterfaceOrientationMask? { view.supportedInterfaceOrientations }

    /// The preferred interface orientation for presentation.
    ///
    /// Delegates to the selected platform-specific view.
    open var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation? { view.preferredInterfaceOrientationForPresentation }

    /// The preferred status bar style.
    ///
    /// Delegates to the selected platform-specific view.
    open var preferredStatusBarStyle: UIStatusBarStyle? { view.preferredStatusBarStyle }

    /// Whether the status bar should be hidden.
    ///
    /// Delegates to the selected platform-specific view.
    open var prefersStatusBarHidden: Bool? { view.prefersStatusBarHidden }

    /// The preferred status bar update animation.
    ///
    /// Delegates to the selected platform-specific view.
    open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation? { view.preferredStatusBarUpdateAnimation }
#endif
    
    /// Called after the mediator is created and connected.
    ///
    /// Delegates to the selected platform-specific view.
    open func didInitialize() { view.didInitialize() }
    
    /// Creates the input needed to initialize the mediator.
    ///
    /// Delegates to the selected platform-specific view.
    ///
    /// - Returns: The view's action interface.
    open func makeInput() -> M.InputV { view.makeInput() }
    
    /// Called when the view is first created.
    ///
    /// Delegates to the selected platform-specific view.
    open func create() { view.create() }
    
    /// Called when the pack is about to become visible.
    ///
    /// Delegates to the selected platform-specific view.
    open func willOpen() { view.willOpen() }
    
    /// Called to animate the view's appearance.
    ///
    /// Delegates to the selected platform-specific view.
    open func animateOpen() { view.animateOpen() }
    
    /// Called after the pack has fully appeared.
    ///
    /// Delegates to the selected platform-specific view.
    open func didOpen() { view.didOpen() }
    
    /// Called when the pack is about to disappear.
    ///
    /// Delegates to the selected platform-specific view.
    open func willClose() { view.willClose() }
    
    /// Called to animate the view's disappearance.
    ///
    /// Delegates to the selected platform-specific view.
    open func animateClose() { view.animateClose() }
    
    /// Called after the pack has fully disappeared.
    ///
    /// Delegates to the selected platform-specific view.
    open func didClose() { view.didClose() }

    /// Called after the view's layout has completed for the first time.
    ///
    /// Delegates to the selected platform-specific view.
    open func didInstall() { view.didInstall() }

    /// Called when the view has been loaded.
    ///
    /// Delegates to the selected platform-specific view.
    open func viewDidLoad() { view.viewDidLoad() }

    /// Called when the view is about to appear.
    ///
    /// Delegates to the selected platform-specific view.
    open func viewWillAppear(_ animated: Bool) { view.viewWillAppear(animated) }

    /// Called during the appearance transition (iOS 13.0+).
    ///
    /// Delegates to the selected platform-specific view.
    @available(iOS 13.0, tvOS 13.0, *)
    open func viewIsAppearing(_ animated: Bool) { view.viewIsAppearing(animated) }

    /// Called when the view has fully appeared.
    ///
    /// Delegates to the selected platform-specific view.
    open func viewDidAppear(_ animated: Bool) { view.viewDidAppear(animated) }

    /// Called when the view is about to disappear.
    ///
    /// Delegates to the selected platform-specific view.
    open func viewWillDisappear(_ animated: Bool) { view.viewWillDisappear(animated) }

    /// Called when the view has fully disappeared.
    ///
    /// Delegates to the selected platform-specific view.
    open func viewDidDisappear(_ animated: Bool) { view.viewDidDisappear(animated) }
}

#endif
