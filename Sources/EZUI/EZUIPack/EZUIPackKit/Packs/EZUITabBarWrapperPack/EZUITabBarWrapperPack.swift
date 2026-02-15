//
//  EZUITabBarWrapperPack.swift
//  EZSDK
//
//  Created by Александр Сенин on 23.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A convenience pack type for wrapping view controllers in a tab bar controller.
///
/// `EZUITabBarWrapperPack` is a type alias that creates a pack with a dummy mediator and view,
/// making it perfect for simple tab bar scenarios where you just need to wrap existing view
/// controllers without implementing a full IMV pack.
///
/// This is ideal when:
/// - You have existing `UIViewController` instances that you want to display as tabs
/// - You don't need a custom mediator or view
/// - You want quick tab bar setup without full IMV implementation
///
/// ## Example: Wrapping multiple view controllers as tabs
///
/// ```swift
/// let homeVC = HomeViewController()
/// let profileVC = ProfileViewController()
/// let settingsVC = SettingsViewController()
/// let tabBar = UIViewController.tabBarWrapper([homeVC, profileVC, settingsVC])
/// present(tabBar, animated: true)
/// ```
///
/// ## Example: Wrapping a single view controller
///
/// ```swift
/// let singleVC = MyViewController()
/// let tabBar = UIViewController.tabBarWrapper(singleVC)
/// ```
///
/// ## Example: Direct pack creation
///
/// ```swift
/// let controllers = [homeVC, profileVC, settingsVC]
/// let tabBar = EZUITabBarWrapperPack.make(controllers)
/// ```
///
/// - Note: This pack uses `EZDummyUIPackM` and `EZDummyUIPackV`, which provide no functionality.
///   For full IMV features, create a custom pack with your own mediator and view.
public typealias EZUITabBarWrapperPack = EZUIPack<
    EZUITabBarWrapperPackI,
    EZDummyUIPackM,
    EZDummyUIPackV<EZDummyUIPackM>
>

extension UIViewController {
    /// Creates a tab bar controller wrapping a single view controller.
    ///
    /// - Parameter controller: The view controller to wrap.
    /// - Returns: A tab bar controller interactor containing the view controller.
    ///
    /// ### Example
    /// ```swift
    /// let tabBar = UIViewController.tabBarWrapper(myViewController)
    /// ```
    public static func tabBarWrapper(_ controller: UIViewController) -> EZUITabBarWrapperPackI {
        tabBarWrapper([controller])
    }
    
    /// Creates a tab bar controller wrapping multiple view controllers.
    ///
    /// - Parameter controllers: The view controllers to wrap as tabs.
    /// - Returns: A tab bar controller interactor containing the view controllers.
    ///
    /// ### Example
    /// ```swift
    /// let tabBar = UIViewController.tabBarWrapper([homeVC, profileVC, settingsVC])
    /// ```
    public static func tabBarWrapper(_ controllers: [UIViewController]) -> EZUITabBarWrapperPackI {
        EZUITabBarWrapperPack.make(controllers)
    }
}

extension EZUITabBarWrapperPack {
    /// Creates a tab bar wrapper pack with the given view controllers.
    ///
    /// - Parameter controllers: The view controllers to display as tabs.
    /// - Returns: A fully initialized tab bar controller interactor.
    public static func make(_ controllers: [UIViewController]) -> EZUITabBarWrapperPackI {
        EZPackMaker.make(
            interactor: { EZUITabBarWrapperPackI(controllers) },
            mediator: { inputI, inputV in EZDummyUIPackM(inputI: inputI, inputV: inputV) },
            view: { EZDummyUIPackV<EZDummyUIPackM>() }
        )
    }
}

/// Interactor for the tab bar wrapper pack.
///
/// Automatically sets up the tab bar with the provided view controllers.
public class EZUITabBarWrapperPackI: EZUITabBarPackI {
    public let access = EZDummyUIPackM.accessI
    
    /// Creates a tab bar wrapper with the given view controllers.
    ///
    /// Automatically sets up the tab bar and transitions to show the controllers.
    ///
    /// - Parameter controllers: The view controllers to display as tabs.
    public init(_ controllers: [UIViewController]) {
         super.init(nibName: nil, bundle: nil)
         ezTransit.tabBarSet(controllers).unsafeTransition().transit()
     }
     
    /// Unsupported initializer.
    ///
    /// Tab bar wrapper packs don't support initialization from storyboards or XIBs.
    @MainActor required init?(coder aDecoder: NSCoder) {
         fatalError("init(coder:) has not been implemented")
     }
}

#endif
