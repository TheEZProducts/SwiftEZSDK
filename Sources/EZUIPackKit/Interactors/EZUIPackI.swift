//
//  EZUIPackI.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation
import UIKit

/// The primary type for creating interactors in the IMV architecture.
///
/// `EZUIPackI` is a type alias that combines `EZUIPackInteractor` and `EZUIPackInteractorProtocol`,
/// providing everything you need to create an interactor. This is the **recommended base type**
/// for all standard interactor implementations.
///
/// An interactor created with this type:
/// - Automatically integrates with UIKit's `UIViewController` lifecycle
/// - Forwards all lifecycle methods to the pack
/// - Delegates interface orientation and status bar appearance to the view
/// - Provides access to the mediator via the `access` property
/// - Supports custom transitions via `transitionController`
///
/// ## Example: Complete interactor implementation
///
/// ```swift
/// class ProfilePackI: EZUIPackI {
///     let access = ProfilePackM.accessI
///     
///     func makeContext() -> Mediator.ContextI {
///         .init(actions: self, viewModel: .init())
///     }
///     
///     func start() {
///         // Load initial data
///         loadProfile()
///     }
///     
///     func didOpen() {
///         // Refresh when pack becomes visible
///         refreshProfile()
///     }
///     
///     private func loadProfile() {
///         viewModel.isLoading = true
///         // ... load data
///         viewModel.profile = loadedProfile
///         viewModel.isLoading = false
///     }
/// }
///
/// extension ProfilePackI: ProfilePackM.InputIProtocol {
///     func editProfile() {
///         // Navigate to edit screen
///     }
///     
///     func deleteProfile() {
///         // Handle deletion
///     }
/// }
/// ```
///
/// ## Lifecycle Methods
///
/// The interactor can override these lifecycle methods:
/// - `didInitialize()` - Called after mediator is created
/// - `start()` - Called when pack first appears
/// - `didCreate()` - Called after view is created
/// - `willOpen()` / `didOpen()` - Called when pack appears
/// - `didInstall()` - Called after first layout
/// - `willClose()` / `didClose()` - Called when pack disappears
///
/// - Note: Always use `EZUIPackI` as your base type for standard interactors. It provides
///   automatic UIKit lifecycle integration and proper pack connection.
public typealias EZUIPackI = EZUIPackInteractor & EZUIPackInteractorProtocol

/// Base class for interactors in the IMV architecture.
///
/// This class integrates with UIKit's `UIViewController` lifecycle and automatically forwards
/// lifecycle calls to the pack. It also delegates interface orientation and status bar
/// appearance to the view component.
///
/// Subclass this and implement `EZUIPackInteractorProtocol` to create your interactor.
///
/// ### Example
/// ```swift
/// class ProfilePackI: EZUIPackInteractor, EZUIPackInteractorProtocol {
///     let access = ProfilePackM.accessI
///     
///     func makeContext() -> Mediator.ContextI {
///         .init(actions: self, viewModel: .init())
///     }
/// }
/// ```
open class EZUIPackInteractor: UIViewController, EZUIPackBaseInteractorProtocol {
    /// The pack that manages this interactor.
    ///
    /// Automatically retrieved during initialization via `EZPackMaker.getPack()`.
    public var pack: (any EZUIPackProtocol) = EZPackMaker.getPack()
    
#if !os(tvOS)
    /// The interface orientations supported by this interactor.
    ///
    /// Delegates to the pack's view, or returns `.all` if not specified.
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        pack.view.supportedInterfaceOrientations ?? .all
    }
    
    /// The preferred interface orientation for presentation.
    ///
    /// Delegates to the pack's view, or uses the superclass implementation.
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        pack.view.preferredInterfaceOrientationForPresentation ??
        super.preferredInterfaceOrientationForPresentation
    }
    
    /// The preferred status bar style.
    ///
    /// Delegates to the pack's view, or uses the superclass implementation.
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "Has no effect on visionOS")
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        pack.view.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    /// Whether the status bar should be hidden.
    ///
    /// Delegates to the pack's view, or uses the superclass implementation.
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "Has no effect on visionOS")
    open override var prefersStatusBarHidden: Bool {
        pack.view.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
    
    /// The preferred status bar update animation.
    ///
    /// Delegates to the pack's view, or uses the superclass implementation.
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "Has no effect on visionOS")
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        pack.view.preferredStatusBarUpdateAnimation ?? super.preferredStatusBarUpdateAnimation
    }
#endif
    
    /// Loads the view from the pack.
    ///
    /// Calls the pack's `loadView(frame:)` method to get the configured view.
    open override func loadView() {
        super.loadView()
        view = pack.loadView(frame: view.frame)
    }
    
    /// Called when the view has been loaded.
    ///
    /// Forwards to the pack's `viewDidLoad()` method.
    open override func viewDidLoad() {
        super.viewDidLoad()
        pack.viewDidLoad()
    }
    
    /// Called when the interactor is added to or removed from a parent view controller.
    ///
    /// Forwards to the pack's `didMove(toParent:)` method.
    ///
    /// - Parameter parent: The parent view controller, or `nil` if removed.
    open override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        pack.didMove(toParent: parent)
    }
    
    /// Called when the view is about to appear.
    ///
    /// Forwards to the pack's `viewWillAppear(_:)` method.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pack.viewWillAppear(animated)
    }
    
    /// Called during the appearance transition (iOS 13.0+).
    ///
    /// Forwards to the pack's `viewIsAppearing(_:)` method.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    @available(iOS 13.0, tvOS 13.0, *)
    open override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        pack.viewIsAppearing(animated)
    }
    
    /// Called when the view's layout has changed.
    ///
    /// Forwards to the pack's `viewDidLayoutSubviews()` method.
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pack.viewDidLayoutSubviews()
    }
    
    /// Called when the view has fully appeared.
    ///
    /// Forwards to the pack's `viewDidAppear(_:)` method.
    ///
    /// - Parameter animated: Whether the appearance was animated.
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pack.viewDidAppear(animated)
    }

    /// Called when the view is about to disappear.
    ///
    /// Forwards to the pack's `viewWillDisappear(_:)` method.
    ///
    /// - Parameter animated: Whether the disappearance is animated.
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pack.viewWillDisappear(animated)
    }

    /// Called when the view has fully disappeared.
    ///
    /// Forwards to the pack's `viewDidDisappear(_:)` method.
    ///
    /// - Parameter animated: Whether the disappearance was animated.
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pack.viewDidDisappear(animated)
    }
}

#endif
