//
//  EZUINavigationWrapperPack.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A convenience pack type for wrapping view controllers in a navigation controller.
///
/// `EZUINavigationWrapperPack` is a type alias that creates a pack with a dummy mediator and view,
/// making it perfect for simple navigation scenarios where you just need to wrap existing view
/// controllers without implementing a full IMV pack.
///
/// This is ideal when:
/// - You have existing `UIViewController` instances that you want to wrap in navigation
/// - You don't need a custom mediator or view
/// - You want quick navigation controller setup without full IMV implementation
///
/// ## Example: Wrapping a single view controller
///
/// ```swift
/// let profileVC = ProfileViewController()
/// let navigationController = UIViewController.navigationWrapper(profileVC)
/// present(navigationController, animated: true)
/// ```
///
/// ## Example: Wrapping multiple view controllers
///
/// ```swift
/// let homeVC = HomeViewController()
/// let profileVC = ProfileViewController()
/// let settingsVC = SettingsViewController()
/// let navigationController = UIViewController.navigationWrapper([homeVC, profileVC, settingsVC])
/// // The first controller will be the root
/// ```
///
/// ## Example: Direct pack creation
///
/// ```swift
/// let controllers = [vc1, vc2, vc3]
/// let navigationController = EZUINavigationWrapperPack.make(controllers)
/// ```
///
/// - Note: This pack uses `EZDummyUIPackM` and `EZDummyUIPackV`, which provide no functionality.
///   For full IMV features, create a custom pack with your own mediator and view.
public typealias EZUINavigationWrapperPack = EZUIPack<
    EZUINavigationWrapperPackI,
    EZDummyUIPackM,
    EZDummyUIPackV<EZDummyUIPackM>
>

extension UIViewController {
    /// Creates a navigation controller wrapping a single view controller.
    ///
    /// - Parameter controller: The view controller to wrap.
    /// - Returns: A navigation controller interactor containing the view controller.
    ///
    /// ### Example
    /// ```swift
    /// let nav = UIViewController.navigationWrapper(myViewController)
    /// ```
    public static func navigationWrapper(_ controller: UIViewController) -> EZUINavigationWrapperPackI {
        navigationWrapper([controller])
    }
    
    /// Creates a navigation controller wrapping multiple view controllers.
    ///
    /// - Parameter controllers: The view controllers to wrap.
    /// - Returns: A navigation controller interactor containing the view controllers.
    ///
    /// ### Example
    /// ```swift
    /// let nav = UIViewController.navigationWrapper([vc1, vc2, vc3])
    /// ```
    public static func navigationWrapper(_ controllers: [UIViewController]) -> EZUINavigationWrapperPackI {
        EZUINavigationWrapperPack.make(controllers)
    }
}

extension EZUINavigationWrapperPack {
    /// Creates a navigation wrapper pack with the given view controllers.
    ///
    /// - Parameter controllers: The view controllers to wrap in the navigation stack.
    /// - Returns: A fully initialized navigation controller interactor.
    public static func make(_ controllers: [UIViewController]) -> EZUINavigationWrapperPackI {
        EZPackMaker.make(
            interactor: { EZUINavigationWrapperPackI(controllers) },
            mediator: { inputI, inputV in EZDummyUIPackM(inputI: inputI, inputV: inputV) },
            view: { EZDummyUIPackV<EZDummyUIPackM>() }
        )
    }
}

/// Interactor for the navigation wrapper pack.
///
/// Automatically sets up the navigation stack with the provided view controllers.
public class EZUINavigationWrapperPackI: EZUINavigationPackI {
    public let access = EZDummyUIPackM.accessI
   
    /// Creates a navigation wrapper with the given view controllers.
    ///
    /// Automatically sets up the navigation stack and transitions to show the controllers.
    ///
    /// - Parameter controllers: The view controllers to display in the navigation stack.
    public init(_ controllers: [UIViewController]) {
        super.init(nibName: nil, bundle: nil)
        ezTransit.navigationSet(controllers).unsafeTransition().transit()
    }
    
    /// Unsupported initializer.
    ///
    /// Navigation wrapper packs don't support initialization from storyboards or XIBs.
    @MainActor required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

#endif
