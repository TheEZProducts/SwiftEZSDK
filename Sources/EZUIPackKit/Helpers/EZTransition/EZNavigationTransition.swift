//
//  EZNavigationTransition.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension EZTransition<UIViewController>{
    /// Creates a transition that pushes a view controller onto the navigation stack.
    ///
    /// - Parameter controller: The view controller to push.
    /// - Returns: A navigation push transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.navigationPush(otherVC)
    ///     .animation(customAnimation)
    ///     .transit()
    /// ```
    public func navigationPush(_ controller: UIViewController) -> EZNavigationPushTransition {
        .init(container: container, controller: controller)
    }
    
    /// Creates a transition that pops the top view controller from the navigation stack.
    ///
    /// - Returns: A navigation pop transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.navigationPop()
    ///     .animate()
    ///     .transit()
    /// ```
    public func navigationPop() -> EZNavigationPopTransition {
        .init(container: container)
    }
    
    /// Creates a transition that pops to a specific view controller.
    ///
    /// - Parameter controller: The view controller to pop to.
    /// - Returns: A navigation pop-to transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.navigationPopTo(targetVC)
    ///     .animate()
    ///     .transit()
    /// ```
    public func navigationPopTo(_ controller: UIViewController) -> EZNavigationPopToTransition {
        .init(container: container, controller: controller)
    }
    
    /// Creates a transition that pops to the root view controller.
    ///
    /// - Returns: A navigation pop-to-root transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.navigationPopToRoot()
    ///     .animate()
    ///     .transit()
    /// ```
    public func navigationPopToRoot() -> EZNavigationPopToRootTransition {
        .init(container: container)
    }
    
    /// Creates a transition that sets the navigation stack to the given controllers.
    ///
    /// - Parameter controllers: The view controllers to set as the navigation stack.
    /// - Returns: A navigation set transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.navigationSet([vc1, vc2, vc3])
    ///     .animate()
    ///     .transit()
    /// ```
    public func navigationSet(_ controllers: [UIViewController]) -> EZNavigationSetTransition {
        .init(container: container, controllers: controllers)
    }
    
    /// Creates a transition that replaces the current view controller with another.
    ///
    /// - Parameter controller: The view controller to replace with.
    /// - Returns: A navigation replace transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.navigationReplace(newVC)
    ///     .animate()
    ///     .transit()
    /// ```
    public func navigationReplace(_ controller: UIViewController) -> EZNavigationReplaceTransition {
        .init(container: container, controller: controller)
    }
    
    /// Creates a transition that replaces only the top view controller.
    ///
    /// - Parameter controller: The view controller to replace the top with.
    /// - Returns: A navigation replace-top transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.navigationReplaceTop(newVC)
    ///     .animate()
    ///     .transit()
    /// ```
    public func navigationReplaceTop(_ controller: UIViewController) -> EZNavigationReplaceTopTransition {
        .init(container: container, controller: controller)
    }
}


//MARK: - EZNavigationTransitionContext
/// Context for child view controller transitions (navigation, tab bar, etc.).
///
/// `EZChildTransitionContext` contains configuration for transitions that affect child view controllers,
/// such as navigation push/pop or tab switching. It's simpler than `EZCustomTransitionContext` as it
/// doesn't include transition types or custom data.
///
/// ### Example: Using in a navigation transition
///
/// ```swift
/// let transition = viewController.ezTransit.navigationPush(otherVC)
///     .animation(customAnimation)
///     .animate()
///     .completion {
///         print("Transition completed")
///     }
///     .transit()
/// ```
public struct EZChildTransitionContext: EZTransitionContextProtocol{
    var _unsafeTransition: Bool = false
    
    var _animate: Bool = false
    var _animation: UIViewControllerAnimatedTransitioning?
    var _completion: (() -> Void)?
    
    var _interactive: ((UIPercentDrivenInteractiveTransition) -> Void)?
}

extension EZTransitionProtocol where Context == EZChildTransitionContext{
    /// Sets whether the transition should be safe (blocked during other transitions).
    ///
    /// - Parameter value: `true` to block during other transitions, `false` to allow.
    /// - Returns: A new transition instance with the safety setting.
    public func safeTransition(_ value: Bool) -> Self {
        var new = self
        new.context._unsafeTransition = !value
        return new
    }
    
    /// Marks the transition as unsafe (allows during other transitions).
    ///
    /// - Returns: A new transition instance marked as unsafe.
    public func unsafeTransition() -> Self {
        var new = self
        new.context._unsafeTransition = true
        return new
    }
    
    /// Sets a custom animation and enables animation.
    ///
    /// - Parameter value: The animation to use.
    /// - Returns: A new transition instance with animation enabled and the animation set.
    public func animation(_ value: UIViewControllerAnimatedTransitioning) -> Self{
        var new = animate()
        new.context._animation = value
        return new
    }
    
    /// Enables animation for the transition.
    ///
    /// - Returns: A new transition instance with animation enabled.
    public func animate() -> Self{
        var new = self
        new.context._animate = true
        return new
    }
    
    /// Sets a completion handler to execute after the transition.
    ///
    /// - Parameter value: The completion closure to execute.
    /// - Returns: A new transition instance with the completion handler set.
    public func completion(_ value: @escaping () -> Void) -> Self{
        var new = self
        new.context._completion = value
        return new
    }
    
    /// Sets an interactive transition handler.
    ///
    /// The closure receives the interactive transition object when the transition starts.
    ///
    /// - Parameter value: A closure that handles the interactive transition.
    /// - Returns: A new transition instance with the interactive handler set.
    public func interactive(_ value: @escaping (UIPercentDrivenInteractiveTransition) -> Void) -> Self{
        var new = self
        new.context._interactive = value
        return new
    }
}

protocol EZNavigationTransitionProtocol: EZTransitionProtocol<EZChildTransitionContext> {}

@available(iOS 13.0, tvOS 13.0, *)
extension EZTransitionProtocol<EZChildTransitionContext>{
    /// Executes the transition asynchronously, waiting for completion.
    ///
    /// This method suspends until the transition completes (or fails to start).
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    ///
    /// ### Example
    /// ```swift
    /// let success = await transition.asyncTransit()
    /// if success {
    ///     print("Transition completed")
    /// }
    /// ```
    @MainActor
    @discardableResult
    public func asyncTransit() async -> Bool {
        await withCheckedContinuation { continuation in
            var continuation = Optional(continuation)
            let transition = completion {[completion = context._completion] in
                completion?()
                continuation?.resume(returning: true)
                continuation = nil
            }
            if !transition.transit() {
                continuation?.resume(returning: false)
                continuation = nil
            }
        }
    }
}

//MARK: - EZNavigationPushTransition
/// A transition that pushes a view controller onto the navigation stack.
///
/// `EZNavigationPushTransition` handles pushing a view controller onto a navigation controller's stack
/// with optional custom animations and interactive transitions.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.navigationPush(otherVC)
///     .animation(.ezOpen(direction: .right))
///     .transit()
/// ```
public struct EZNavigationPushTransition: EZNavigationTransitionProtocol{
    private var container: UIViewController
    private var controller: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a navigation push transition.
    ///
    /// - Parameters:
    ///   - container: The view controller containing or being the navigation controller.
    ///   - controller: The view controller to push.
    public init(container: UIViewController, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    /// Executes the push transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            !(controller is UINavigationController),
            let navigationController = (container as? UINavigationController) ?? container.navigationController
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.pushViewController(controller, animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
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

//MARK: - EZNavigationPopTransition
/// A transition that pops the top view controller from the navigation stack.
///
/// `EZNavigationPopTransition` handles popping the top view controller from a navigation controller's stack
/// with optional custom animations and interactive transitions.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.navigationPop()
///     .animation(.ezClose(direction: .right))
///     .transit()
/// ```
public struct EZNavigationPopTransition: EZNavigationTransitionProtocol{
    private var container: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a navigation pop transition.
    ///
    /// - Parameter container: The view controller containing or being the navigation controller.
    public init(container: UIViewController) {
        self.container = container
    }
    
    /// Executes the pop transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let navigationController = (container as? UINavigationController) ?? container.navigationController
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.popViewController(animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
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

//MARK: - EZNavigationPopToRootTransition
/// A transition that pops all view controllers except the root.
///
/// `EZNavigationPopToRootTransition` handles popping all view controllers from a navigation controller's stack
/// until only the root view controller remains, with optional custom animations.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.navigationPopToRoot()
///     .animate()
///     .transit()
/// ```
public struct EZNavigationPopToRootTransition: EZNavigationTransitionProtocol{
    private var container: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a navigation pop-to-root transition.
    ///
    /// - Parameter container: The view controller containing or being the navigation controller.
    public init(container: UIViewController) {
        self.container = container
    }
    
    /// Executes the pop-to-root transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let navigationController = (container as? UINavigationController) ?? container.navigationController
        else { return false }
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.popToRootViewController(animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
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

//MARK: - EZNavigationPopToTransition
/// A transition that pops to a specific view controller in the navigation stack.
///
/// `EZNavigationPopToTransition` handles popping view controllers from a navigation controller's stack
/// until the specified view controller is at the top, with optional custom animations.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.navigationPopTo(targetVC)
///     .animate()
///     .transit()
/// ```
public struct EZNavigationPopToTransition: EZNavigationTransitionProtocol{
    private var container: UIViewController
    private var controller: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a navigation pop-to transition.
    ///
    /// - Parameters:
    ///   - container: The view controller containing or being the navigation controller.
    ///   - controller: The view controller to pop to.
    public init(container: UIViewController, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    /// Executes the pop-to transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            !(controller is UINavigationController),
            let navigationController = (container as? UINavigationController) ?? container.navigationController
        else { return false }
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.popToViewController(controller, animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
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

//MARK: - EZNavigationSetTransition
/// A transition that sets the navigation controller's view controllers.
///
/// `EZNavigationSetTransition` replaces the entire navigation stack with the provided
/// view controllers, with optional custom animations.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.navigationSet([rootVC, vc1, vc2])
///     .animate()
///     .transit()
/// ```
public struct EZNavigationSetTransition: EZNavigationTransitionProtocol{
    private var container: UIViewController
    private var controllers: [UIViewController]
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a navigation set transition.
    ///
    /// - Parameters:
    ///   - container: The view controller containing or being the navigation controller.
    ///   - controllers: The view controllers to set as the navigation stack.
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
            controllers.first(where: { $0 is UINavigationController }) == nil,
            let navigationController = (container as? UINavigationController) ?? container.navigationController
        else { return false }
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.setViewControllers(controllers, animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
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

//MARK: - EZNavigationReplaceTransition
/// A transition that replaces the current view controller in the navigation stack.
///
/// `EZNavigationReplaceTransition` handles replacing the current view controller with another
/// in the navigation stack, maintaining the rest of the stack, with optional custom animations.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.navigationReplace(newVC)
///     .animate()
///     .transit()
/// ```
public struct EZNavigationReplaceTransition: EZReplaceTransitionProtocol, EZNavigationTransitionProtocol{
    private var container: UIViewController
    private var controller: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a navigation replace transition.
    ///
    /// - Parameters:
    ///   - container: The view controller to replace.
    ///   - controller: The view controller to replace with.
    public init(container: UIViewController, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    /// Executes the replace transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            !(controller is UINavigationController),
            let navigationController = container.navigationController,
            let index = navigationController.viewControllers.firstIndex(of: container)
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        
        var controllers = navigationController.viewControllers
        controllers[index] = controller
        
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.setViewControllers(controllers, animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
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

//MARK: - EZNavigationReplaceTopTransition
/// A transition that replaces only the top view controller in the navigation stack.
///
/// `EZNavigationReplaceTopTransition` handles replacing only the top (most recent) view controller
/// in the navigation stack, leaving the rest of the stack intact, with optional custom animations.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.navigationReplaceTop(newVC)
///     .animate()
///     .transit()
/// ```
public struct EZNavigationReplaceTopTransition: EZTransitionProtocol, EZNavigationTransitionProtocol{
    private var container: UIViewController
    private var controller: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZChildTransitionContext()
    
    /// Creates a navigation replace-top transition.
    ///
    /// - Parameters:
    ///   - container: The view controller containing or being the navigation controller.
    ///   - controller: The view controller to replace the top with.
    public init(container: UIViewController, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    /// Executes the replace-top transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            !(controller is UINavigationController),
            let navigationController = (container as? UINavigationController) ?? container.navigationController,
            let topController = navigationController.topViewController,
            let index = navigationController.viewControllers.firstIndex(of: topController)
        else { return false }
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        if
            !context._unsafeTransition,
            navigationController.transitionCoordinator != nil
        { return false }
        
        var controllers = navigationController.viewControllers
        controllers[index] = controller
        
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.setViewControllers(controllers, animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
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
#endif
