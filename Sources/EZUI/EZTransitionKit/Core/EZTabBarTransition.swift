//
//  EZTabBarTransition.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension EZTransition<UIViewController>{
    /// Creates a transition that sets the tab bar's view controllers.
    ///
    /// - Parameter controllers: The view controllers to set as tabs.
    /// - Returns: A tab bar set transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.tabBarSet([vc1, vc2, vc3])
    ///     .animate()
    ///     .transit()
    /// ```
    public func tabBarSet(_ controllers: [UIViewController]) -> EZTabBarSetTransition {
        .init(container: container, controllers: controllers)
    }
    
    /// Creates a transition that sets a single view controller as the tab bar's content.
    ///
    /// - Parameter controller: The view controller to set.
    /// - Returns: A tab bar set transition instance.
    public func tabBarSet(_ controller: UIViewController) -> EZTabBarSetTransition {
        .init(container: container, controllers: [controller])
    }
    
    /// Creates a transition that selects a specific view controller tab.
    ///
    /// - Parameter controller: The view controller to select.
    /// - Returns: A tab bar select transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.tabBarSelect(targetVC)
    ///     .animation(customAnimation)
    ///     .transit()
    /// ```
    public func tabBarSelect(_ controller: UIViewController) -> EZTabBarSelectControllerTransition {
        .init(container: container, controller: controller)
    }
    
    /// Creates a transition that selects a tab by index.
    ///
    /// - Parameter index: The index of the tab to select.
    /// - Returns: A tab bar select transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.tabBarSelect(2)
    ///     .animate()
    ///     .transit()
    /// ```
    public func tabBarSelect(_ index: Int) -> EZTabBarSelectIndexTransition {
        .init(container: container, index: index)
    }
    
    /// Creates a transition that selects the next tab.
    ///
    /// - Returns: A tab bar next transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.tabBarNext()
    ///     .animate()
    ///     .transit()
    /// ```
    public func tabBarNext() -> EZTabBarNextTransition {
        .init(container: container)
    }
    
    /// Creates a transition that selects the previous tab.
    ///
    /// - Returns: A tab bar back transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.tabBarBack()
    ///     .animate()
    ///     .transit()
    /// ```
    public func tabBarBack() -> EZTabBarBackTransition {
        .init(container: container)
    }
    
    /// Creates a transition that replaces a tab with another view controller.
    ///
    /// - Parameter controller: The view controller to replace with.
    /// - Returns: A tab bar replace transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.tabBarReplace(newVC)
    ///     .animate()
    ///     .transit()
    /// ```
    public func tabBarReplace(_ controller: UIViewController) -> EZTabBarReplaceTransition {
        .init(container: container, controller: controller)
    }
}

protocol EZTabBarTransitionProtocol: EZTransitionProtocol<EZChildTransitionContext>{}

//MARK: - EZTabBarSetTransition
/// A transition that sets the tab bar controller's view controllers.
///
/// `EZTabBarSetTransition` replaces all tabs in a tab bar controller with the provided
/// view controllers.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.tabBarSet([homeVC, profileVC, settingsVC])
///     .animation(EZShiftAnimation.ezShift(direction: .left))
///     .transit()
/// ```
public struct EZTabBarSetTransition: EZTabBarTransitionProtocol{
    private var container: UIViewController
    private var controllers: [UIViewController]
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a tab bar set transition.
    ///
    /// - Parameters:
    ///   - container: The view controller containing or being the tab bar controller.
    ///   - controllers: The view controllers to set as tabs.
    public init(container: UIViewController, controllers: [UIViewController]) {
        self.container = container
        self.controllers = controllers
    }
    
    /// Executes the set transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let tabBarController = (container as? UITabBarController) ?? container.tabBarController
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.setViewControllers(controllers, animated: context._animate)
            if let transitionCoordinator = tabBarController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZTabBarSetIndexTransition
/// A transition that selects a tab by index.
///
/// `EZTabBarSelectIndexTransition` handles selecting a specific tab in a tab bar controller
/// by its index, with optional custom animations and interactive transitions.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.tabBarSelect(2)
///     .animation(.ezShift(direction: .left))
///     .transit()
/// ```
public struct EZTabBarSelectIndexTransition: EZTabBarTransitionProtocol{
    private var container: UIViewController
    private var index: Int
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a tab bar select index transition.
    ///
    /// - Parameters:
    ///   - container: The view controller containing or being the tab bar controller.
    ///   - index: The index of the tab to select.
    public init(container: UIViewController, index: Int) {
        self.container = container
        self.index = index
    }
    
    /// Executes the select index transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let tabBarController = (container as? UITabBarController) ?? container.tabBarController
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.selectedIndex = index
            if let transitionCoordinator = tabBarController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZTabBarNextTransition
/// A transition that selects the next tab.
///
/// `EZTabBarNextTransition` handles selecting the next tab in a tab bar controller
/// (increments the selected index), with optional custom animations.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.tabBarNext()
///     .animate()
///     .transit()
/// ```
public struct EZTabBarNextTransition: EZTabBarTransitionProtocol {
    private var container: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a tab bar next transition.
    ///
    /// - Parameter container: The view controller containing or being the tab bar controller.
    public init(container: UIViewController) {
        self.container = container
    }
    
    /// Executes the next transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let tabBarController = (container as? UITabBarController) ?? container.tabBarController,
            (tabBarController.selectedIndex + 1) < tabBarController.viewControllers?.count ?? 0
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map { context._interactive?($0) }
            tabBarController.selectedIndex += 1
            if let transitionCoordinator = tabBarController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZTabBarBackTransition
/// A transition that selects the previous tab.
///
/// `EZTabBarBackTransition` handles selecting the previous tab in a tab bar controller
/// (decrements the selected index), with optional custom animations.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.tabBarBack()
///     .animate()
///     .transit()
/// ```
public struct EZTabBarBackTransition: EZTabBarTransitionProtocol{
    private var container: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a tab bar back transition.
    ///
    /// - Parameter container: The view controller containing or being the tab bar controller.
    public init(container: UIViewController) {
        self.container = container
    }
    
    /// Executes the back transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let tabBarController = (container as? UITabBarController) ?? container.tabBarController,
            (tabBarController.selectedIndex - 1) >= 0
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.selectedIndex -= 1
            if let transitionCoordinator = tabBarController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZTabBarSelectControllerTransition
/// A transition that selects a tab by view controller.
///
/// `EZTabBarSelectControllerTransition` handles selecting a specific tab in a tab bar controller
/// by finding the view controller in the tab bar's view controllers array, with optional custom animations.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.tabBarSelect(targetVC)
///     .animation(customAnimation)
///     .transit()
/// ```
public struct EZTabBarSelectControllerTransition: EZTabBarTransitionProtocol{
    private var container: UIViewController
    private var controller: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a tab bar select controller transition.
    ///
    /// - Parameters:
    ///   - container: The view controller containing or being the tab bar controller.
    ///   - controller: The view controller to select.
    public init(container: UIViewController, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    /// Executes the select controller transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let tabBarController = (container as? UITabBarController) ?? container.tabBarController,
            let index = tabBarController.viewControllers?.firstIndex(of: controller)
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.selectedIndex = index
            if let transitionCoordinator = tabBarController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZTabBarReplaceTransition
/// A transition that replaces a tab with another view controller.
///
/// `EZTabBarReplaceTransition` handles replacing the currently selected tab's view controller
/// with another view controller, with optional custom animations.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.tabBarReplace(newVC)
///     .animate()
///     .transit()
/// ```
public struct EZTabBarReplaceTransition: EZReplaceTransitionProtocol, EZTabBarTransitionProtocol{
    private var container: UIViewController
    private var controller: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a tab bar replace transition.
    ///
    /// - Parameters:
    ///   - container: The view controller containing or being the tab bar controller.
    ///   - controller: The view controller to replace with. If it's already in the tab bar, selects it instead.
    public init(container: UIViewController, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    /// Executes the replace transition.
    ///
    /// If the controller is already in the tab bar, selects it. Otherwise, replaces the currently selected tab.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let tabBarController = container.tabBarController
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        if let index = tabBarController.viewControllers?.firstIndex(of: controller){
            indexTransit(
                tabBarController: tabBarController,
                index: index
            )
        }else if
            let controllers = tabBarController.viewControllers,
            tabBarController.selectedIndex < controllers.count
        {
            replaceTransit(
                tabBarController: tabBarController,
                controllers: controllers
            )
        }else{ return false }
        
        return true
    }
    
    @MainActor
    private func indexTransit(
        tabBarController: UITabBarController,
        index: Int
    ) {
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.selectedIndex = index
            if let transitionCoordinator = tabBarController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
    }
    
    @MainActor
    private func replaceTransit(
        tabBarController: UITabBarController,
        controllers: [UIViewController]
    ) {
        var controllers = controllers
        controllers[tabBarController.selectedIndex] = controller
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.setViewControllers(controllers, animated: context._animate)
            if let transitionCoordinator = tabBarController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
    }
}
#endif
