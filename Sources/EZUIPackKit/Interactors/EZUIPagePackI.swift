//
//  EZUIPagePack.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// Protocol for page view controller packs in the IMV architecture.
///
/// Combines `UIPageViewController` with `EZUIPackProtocol` to create page-based navigation packs.
/// Use this when creating packs that use `UIPageViewController` for swipable page navigation.
///
/// ### Example
/// ```swift
/// class TutorialPack: EZUIPagePackProtocol {
///     // Implement pack requirements
/// }
/// ```
public protocol EZUIPagePackProtocol: UIPageViewController, EZUIPackProtocol {}

/// The primary type for creating page view controller interactors in the IMV architecture.
///
/// `EZUIPagePackI` is a type alias that combines `EZUIPagePackInteractor` and `EZUIPagePackProtocol`,
/// providing everything you need to create a page-based pack. This is the **recommended base type**
/// for all page view controller implementations.
///
/// A page interactor created with this type:
/// - Integrates `UIPageViewController` with the IMV pattern
/// - Supports page-based navigation (swipe between pages)
/// - Automatically forwards lifecycle methods to the pack
/// - Provides all standard `EZUIPackI` functionality
///
/// ## Example: Complete page interactor implementation
///
/// ```swift
/// class TutorialPagePackI: EZUIPagePackI {
///     let access = TutorialPagePackM.accessI
///     
///     func makeContext() -> Mediator.ContextI {
///         .init(actions: self, viewModel: .init())
///     }
///     
///     func start() {
///         // Set up initial page
///         let firstPage = TutorialPage1Pack.make()
///         setViewControllers([firstPage], direction: .forward, animated: false)
///     }
/// }
/// ```
///
/// - Note: Always use `EZUIPagePackI` as your base type for page-based packs.
///   It provides proper integration with UIKit's page view controller and the IMV architecture.
public typealias EZUIPagePackI = EZUIPagePackInteractor & EZUIPagePackProtocol

/// Base class for page view controller interactors in the IMV architecture.
///
/// This class integrates `UIPageViewController` with the IMV pattern, providing:
/// - Automatic pack lifecycle integration
/// - Interface orientation and status bar customization from the view
///
/// ### Example
/// ```swift
/// class TutorialPackI: EZUIPagePackInteractor, EZUIPagePackProtocol {
///     // Implement pack requirements
/// }
/// ```
open class EZUIPagePackInteractor: UIPageViewController, EZUIPackBaseInteractorProtocol {
    /// The pack that manages this interactor.
    ///
    /// Automatically retrieved during initialization via `EZPackMaker.getPack()`.
    public var pack: (any EZUIPackProtocol) = EZPackMaker.getPack()
    
#if !os(tvOS)
    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        delegate?.pageViewControllerSupportedInterfaceOrientations?(self) ??
        pack.view.supportedInterfaceOrientations ??
        super.supportedInterfaceOrientations
    }
    
    open override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        delegate?.pageViewControllerPreferredInterfaceOrientationForPresentation?(self) ??
        pack.view.preferredInterfaceOrientationForPresentation ??
        super.preferredInterfaceOrientationForPresentation
    }
    
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "Has no effect on visionOS")
    open override var preferredStatusBarStyle: UIStatusBarStyle {
        pack.view.preferredStatusBarStyle ?? super.preferredStatusBarStyle
    }
    
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "Has no effect on visionOS")
    open override var prefersStatusBarHidden: Bool {
        pack.view.prefersStatusBarHidden ?? super.prefersStatusBarHidden
    }
    
    @available(visionOS, introduced: 1.0, deprecated: 1.0, message: "Has no effect on visionOS")
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        pack.view.preferredStatusBarUpdateAnimation ?? super.preferredStatusBarUpdateAnimation
    }
#endif
    
    open override func loadView() {
        super.loadView()
        let oldView: UIView = view
        view = pack.loadView(frame: view.frame)
        view.addSubview(oldView)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        pack.viewDidLoad()
    }
    
    open override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        pack.didMove(toParent: parent)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        pack.viewWillAppear(animated)
    }
    
    @available(iOS 13.0, tvOS 13.0, *)
    open override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        pack.viewIsAppearing(animated)
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pack.viewDidLayoutSubviews()
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        pack.viewDidAppear(animated)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pack.viewWillDisappear(animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pack.viewDidDisappear(animated)
    }
}
#endif
