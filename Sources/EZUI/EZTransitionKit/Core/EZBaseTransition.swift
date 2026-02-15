//
//  EZBaseTransition.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension EZTransition<UIViewController>{
    /// Creates a transition that presents a view controller modally.
    ///
    /// - Parameter controller: The view controller to present.
    /// - Returns: A present transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.present(otherVC)
    ///     .presentationStyle(.fullScreen)
    ///     .animation(.coverVertical)
    ///     .animate()
    ///     .transit()
    /// ```
    public func present(_ controller: UIViewController) -> EZPresentTransition<Container> {
        .init(container: container, controller: controller)
    }
    
    /// Creates a transition that dismisses the current view controller.
    ///
    /// - Returns: A dismiss transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.dismiss()
    ///     .animate()
    ///     .transit()
    /// ```
    public func dismiss() -> EZDismissTransition {
        .init(controller: container)
    }
}

extension EZTransition<EZContainerView>{
    /// Creates a transition that presents a view controller in a container view.
    ///
    /// - Parameter controller: The view controller to present.
    /// - Returns: A present transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = containerView.transit.present(vc)
    ///     .animate()
    ///     .transit()
    /// ```
    public func present(_ controller: UIViewController) -> EZPresentTransition<Container> {
        .init(container: container, controller: controller)
    }
}

//MARK: - EZBaseTransitionContext
/// Context for base transitions (present/dismiss).
///
/// `EZBaseTransitionContext` contains configuration for modal presentation and dismissal transitions,
/// including presentation styles, transition styles, animations, and interactive transitions.
///
/// ### Example: Using in a present transition
///
/// ```swift
/// let transition = viewController.ezTransit.present(otherVC)
///     .presentationStyle(.fullScreen)
///     .animation(.ezOpen(direction: .up))
///     .completion {
///         print("Presentation completed")
///     }
///     .transit()
/// ```
public struct EZBaseTransitionContext: EZTransitionContextProtocol{
    var _unsafeTransition: Bool = false
    
    var _animate: Bool = false
    var _animation: UIViewControllerAnimatedTransitioning?
    var _transitionStyle: UIModalTransitionStyle?
    var _presentationStyle: UIModalPresentationStyle?
    var _completion: (() -> Void)?
    
    var _interactive: ((UIPercentDrivenInteractiveTransition) -> Void)?
}

extension EZTransitionProtocol where Context == EZBaseTransitionContext {
    /// Sets the modal presentation style.
    ///
    /// - Parameter value: The presentation style to use.
    /// - Returns: A new transition instance with the presentation style set.
    public func presentationStyle(_ value: UIModalPresentationStyle) -> Self {
        var new = self
        new.context._presentationStyle = value
        return new
    }
    
    /// Sets the modal transition style and enables animation.
    ///
    /// - Parameter value: The transition style to use.
    /// - Returns: A new transition instance with animation enabled and the style set.
    public func animation(_ value: UIModalTransitionStyle) -> Self {
        var new = animate()
        new.context._transitionStyle = value
        return new
    }
    
    /// Sets a custom animation and enables animation.
    ///
    /// - Parameter value: The animation to use.
    /// - Returns: A new transition instance with animation enabled and the animation set.
    public func animation(_ value: UIViewControllerAnimatedTransitioning) -> Self {
        var new = animate()
        new.context._animation = value
        return new
    }
    
    /// Enables animation for the transition.
    ///
    /// - Returns: A new transition instance with animation enabled.
    public func animate() -> Self {
        var new = self
        new.context._animate = true
        return new
    }
    
    /// Sets a completion handler to execute after the transition.
    ///
    /// - Parameter value: The completion closure to execute.
    /// - Returns: A new transition instance with the completion handler set.
    public func completion(_ value: @escaping () -> Void) -> Self {
        var new = self
        new.context._completion = value
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
    
    /// Sets an interactive transition handler.
    ///
    /// The closure receives the interactive transition object when the transition starts.
    ///
    /// - Parameter value: A closure that handles the interactive transition.
    /// - Returns: A new transition instance with the interactive handler set.
    public func interactive(_ value: @escaping (UIPercentDrivenInteractiveTransition) -> Void) -> Self {
        var new = self
        new.context._interactive = value
        return new
    }
}

protocol EZBaseTransitionProtocol: EZTransitionProtocol<EZBaseTransitionContext> {}

@available(iOS 13.0, tvOS 13.0, *)
extension EZTransitionProtocol<EZBaseTransitionContext>{
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
    ///     print("Presentation completed")
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

//MARK: - EZPresentTransition
/// A transition that presents a view controller modally.
///
/// `EZPresentTransition` handles modal presentation of view controllers, either from a
/// `UIViewController` (full screen) or from an `EZContainerView` (within a container).
///
/// ### Example: Presenting from a view controller
///
/// ```swift
/// let transition = viewController.ezTransit.present(otherVC)
///     .presentationStyle(.fullScreen)
///     .animation(.ezOpen(direction: .up))
///     .transit()
/// ```
///
/// ### Example: Presenting in a container view
///
/// ```swift
/// let transition = containerView.transit.present(vc)
///     .animate()
///     .transit()
/// ```
public struct EZPresentTransition<Container>: EZBaseTransitionProtocol{
    private var container: Container
    private var controller: UIViewController
    
    /// The transition context containing presentation and animation settings.
    public var context = EZBaseTransitionContext()
    
    /// Creates a present transition.
    ///
    /// - Parameters:
    ///   - container: The container (view controller or container view) to present from.
    ///   - controller: The view controller to present.
    public init(container: Container, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    /// Executes the present transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        if let controllerTransition = self as? EZPresentTransition<UIViewController>{
            return controllerTransition.transit()
        }else if let controllerTransition = self as? EZPresentTransition<EZContainerView>{
            return controllerTransition.transit()
        }else{ return false }
    }
}

extension EZPresentTransition<UIViewController>{
    /// Executes the present transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        
        controller.wrappDelegateForTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            context._transitionStyle.map{ controller.modalTransitionStyle = $0 }
            context._presentationStyle.map{ controller.modalPresentationStyle = $0 }
            container.present(controller, animated: context._animate, completion: context._completion)
        }
        return true
    }
}

extension EZPresentTransition<EZContainerView>{
    /// Executes the present transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        if
            !context._unsafeTransition,
            controller.isBeingPresented || controller.isBeingDismissed
        { return false }
        controller.wrappDelegateForTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            context._transitionStyle.map{ controller.modalTransitionStyle = $0 }
            controller.modalPresentationStyle = .currentContext
            container.present(controller, animated: context._animate, completion: context._completion)
        }
        return true
    }
}

//MARK: - EZDismissTransition
/// A transition that dismisses a modally presented view controller.
///
/// `EZDismissTransition` handles the dismissal of a modally presented view controller
/// with optional custom animations and interactive transitions.
///
/// ### Example
/// ```swift
/// let transition = presentedVC.ezTransit.dismiss()
///     .animation(EZCloseAnimation.ezClose(direction: .down))
///     .animate()
///     .completion {
///         print("Dismissal completed")
///     }
///     .transit()
/// ```
public struct EZDismissTransition: EZBaseTransitionProtocol{
    private var controller: UIViewController
    
    /// The transition context containing animation and completion settings.
    public var context = EZBaseTransitionContext()
    
    /// Creates a dismiss transition.
    ///
    /// - Parameter controller: The view controller to dismiss.
    public init(controller: UIViewController) {
        self.controller = controller
    }
    
    /// Executes the dismiss transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        if
            !context._unsafeTransition,
            controller.isBeingPresented || controller.isBeingDismissed
        { return false }
        controller.rootParent.wrappDelegateForTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            context._transitionStyle.map{ controller.modalTransitionStyle = $0 }
            controller.dismiss(animated: context._animate, completion: context._completion)
        }
        return true
    }
}
#endif
