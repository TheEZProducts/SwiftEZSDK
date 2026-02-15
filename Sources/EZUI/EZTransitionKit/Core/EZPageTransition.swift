//
//  EZPageTransition.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension EZTransition<UIViewController>{
    /// Creates a transition that sets the page view controller's view controllers.
    ///
    /// - Parameter controllers: The view controllers to set.
    /// - Returns: A page set transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.pageSet([page1, page2, page3])
    ///     .direction(.forward)
    ///     .animate()
    ///     .transit()
    /// ```
    public func pageSet(_ controllers: [UIViewController]) -> EZPageSetTransition {
        .init(container: container, controllers: controllers)
    }
}

//MARK: - EZPageTransitionContext
/// Context for page view controller transitions.
///
/// `EZPageTransitionContext` contains configuration for page view controller transitions,
/// including navigation direction and animation settings.
///
/// ### Example: Using in a page transition
///
/// ```swift
/// let transition = viewController.ezTransit.pageSet([page1, page2])
///     .direction(.forward)
///     .animate()
///     .completion {
///         print("Page transition completed")
///     }
///     .transit()
/// ```
public struct EZPageTransitionContext: EZTransitionContextProtocol{
    var _unsafeTransition: Bool = false
    
    var _animate: Bool = false
    var _direction: UIPageViewController.NavigationDirection = .forward
    var _completion: (() -> Void)?
}

extension EZTransitionProtocol where Context == EZPageTransitionContext{
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
    
    /// Sets the navigation direction for the page transition.
    ///
    /// - Parameter value: The direction (.forward or .reverse).
    /// - Returns: A new transition instance with the direction set.
    public func direction(_ value: UIPageViewController.NavigationDirection) -> Self{
        var new = self
        new.context._direction = value
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
}

protocol EZPageTransitionProtocol: EZTransitionProtocol<EZPageTransitionContext>{}

@available(iOS 13.0, tvOS 13.0, *)
extension EZTransitionProtocol<EZPageTransitionContext>{
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
    ///     print("Page transition completed")
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

//MARK: - EZPageSetTransition
/// A transition that sets the page view controller's view controllers.
///
/// `EZPageSetTransition` sets the view controllers displayed by a page view controller
/// with optional animation and navigation direction.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.pageSet([page1, page2, page3])
///     .direction(.forward)
///     .animate()
///     .transit()
/// ```
public struct EZPageSetTransition: EZPageTransitionProtocol{
    private var container: UIViewController
    private var controllers: [UIViewController]
    
    /// The transition context containing direction and animation settings.
    public var context = EZPageTransitionContext()
    
    /// Creates a page set transition.
    ///
    /// - Parameters:
    ///   - container: The view controller containing or being the page view controller.
    ///   - controllers: The view controllers to set.
    public init(container: UIViewController, controllers: [UIViewController]) {
        self.container = container
        self.controllers = controllers
    }
    
    /// Executes the page set transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let pageController = (container as? UIPageViewController) ?? container.pageController
        else { return false }
        pageController.setViewControllers(
            controllers,
            direction: context._direction,
            animated: context._animate,
            completion: {[completion = context._completion] _ in completion?() }
        )
        return true
    }
}
#endif
