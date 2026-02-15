//
//  Untitled.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//
#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewControllerAnimatedTransitioning where Self == EZOpenAnimation {
    /// Creates a default open animation (slides up, 0.5 seconds).
    ///
    /// ### Example
    /// ```swift
    /// viewController.transitioningDelegate = EZUIViewControllerTransitioningDelegate(
    ///     delegate: nil,
    ///     animation: .ezOpen
    /// )
    /// ```
    public static var ezOpen: Self { .init() }
    
    /// Creates a custom open animation.
    ///
    /// - Parameters:
    ///   - direction: The direction from which the view controller slides in.
    ///   - duration: The duration of the animation in seconds.
    /// - Returns: A configured open animation.
    ///
    /// ### Example
    /// ```swift
    /// let animation = UIViewControllerAnimatedTransitioning.ezOpen(
    ///     direction: .right,
    ///     duration: 0.3
    /// )
    /// ```
    public static func ezOpen(
        direction: EZAnimationDirection = .up,
        duration: TimeInterval = 0.5
    ) -> Self { .init(direction: direction, duration: duration) }
}

/// The direction for transition animations.
///
/// Used to specify which direction a view controller should slide in or out.
public enum EZAnimationDirection{
    /// Slide from or to the top.
    case up
    /// Slide from or to the bottom.
    case down
    /// Slide from or to the right.
    case right
    /// Slide from or to the left.
    case left
}

/// An animation that slides a view controller in from a specified direction.
///
/// `EZOpenAnimation` animates the presentation of a view controller by sliding it in from
/// one of four directions (up, down, left, right) while slightly moving the current view
/// controller in the opposite direction.
///
/// ### Example: Using in a transition delegate
///
/// ```swift
/// let animation = EZOpenAnimation()
/// animation.direction = .right
/// animation.duration = 0.3
///
/// let delegate = EZUIViewControllerTransitioningDelegate(
///     delegate: nil,
///     animation: animation
/// )
/// viewController.transitioningDelegate = delegate
/// ```
public class EZOpenAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    /// The duration of the animation in seconds.
    ///
    /// Defaults to `0.5` seconds.
    public var duration: TimeInterval = 0.5
    
    /// The direction from which the view controller slides in.
    ///
    /// Defaults to `.up`.
    public var direction: EZAnimationDirection = .up
    
    
    init(direction: EZAnimationDirection = .up, duration: TimeInterval? = nil){
        self.direction = direction
        if let duration { self.duration = duration }
    }
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let toViewC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        let fromView = transitionContext.view(forKey: .from)
        let container = transitionContext.containerView
        container.addSubview(toViewC.view)
        toViewC.view.frame = transitionContext.finalFrame(for: toViewC)
        
        preparePosition(toView: toViewC.view, container: container)
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0.0,
            options: [.curveEaseInOut]
        ) {
            toViewC.view.transform.ty = 0
            toViewC.view.transform.tx = 0
            self.animatePosition(fromView: fromView, container: container)
        } completion: { _ in
            fromView?.transform.ty = 0
            fromView?.transform.tx = 0
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func preparePosition(toView: UIView, container: UIView){
        switch direction {
        case .up:
            toView.transform.ty = container.bounds.height
        case .down:
            toView.transform.ty = -container.bounds.height
        case .right:
            toView.transform.tx = -container.bounds.width
        case .left:
            toView.transform.tx = container.bounds.width
        }
    }
    
    private func animatePosition(fromView: UIView?, container: UIView){
        switch direction {
        case .up:
            fromView?.transform.ty -= container.bounds.height * 0.3
        case .down:
            fromView?.transform.ty = container.bounds.height * 0.3
        case .right:
            fromView?.transform.tx = container.bounds.width * 0.3
        case .left:
            fromView?.transform.tx -= container.bounds.width * 0.3
        }
    }
}

extension UIViewControllerAnimatedTransitioning where Self == EZCloseAnimation {
    /// Creates a default close animation (slides up, 0.5 seconds).
    ///
    /// ### Example
    /// ```swift
    /// viewController.transitioningDelegate = EZUIViewControllerTransitioningDelegate(
    ///     delegate: nil,
    ///     animation: .ezClose
    /// )
    /// ```
    public static var ezClose: Self { .init() }
    
    /// Creates a custom close animation.
    ///
    /// - Parameters:
    ///   - direction: The direction to which the view controller slides out.
    ///   - duration: The duration of the animation in seconds.
    /// - Returns: A configured close animation.
    ///
    /// ### Example
    /// ```swift
    /// let animation = UIViewControllerAnimatedTransitioning.ezClose(
    ///     direction: .right,
    ///     duration: 0.3
    /// )
    /// ```
    public static func ezClose(
        direction: EZAnimationDirection = .up,
        duration: TimeInterval = 0.5
    ) -> Self { .init(direction: direction, duration: duration) }
}

/// An animation that slides a view controller out to a specified direction.
///
/// `EZCloseAnimation` animates the dismissal of a view controller by sliding it out to
/// one of four directions (up, down, left, right) while restoring the underlying view
/// controller to its original position.
///
/// ### Example: Using in a transition delegate
///
/// ```swift
/// let animation = EZCloseAnimation()
/// animation.direction = .right
/// animation.duration = 0.3
///
/// let delegate = EZUIViewControllerTransitioningDelegate(
///     delegate: nil,
///     animation: animation
/// )
/// viewController.transitioningDelegate = delegate
/// ```
public class EZCloseAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    /// The duration of the animation in seconds.
    ///
    /// Defaults to `0.5` seconds.
    public var duration: TimeInterval = 0.5
    
    /// The direction to which the view controller slides out.
    ///
    /// Defaults to `.up`.
    public var direction: EZAnimationDirection = .up
    
    init(direction: EZAnimationDirection = .up, duration: TimeInterval? = nil) {
        self.direction = direction
        if let duration { self.duration = duration }
    }
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromViewC = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        let toView = transitionContext.view(forKey: .to)
        let container = transitionContext.containerView
        if let toView{
            container.addSubview(toView)
            container.bringSubviewToFront(fromViewC.view)
        }
       
        preparePosition(toView: toView, container: container)
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseInOut]
        ){
            self.animatePosition(fromView: fromViewC.view, container: container)
            toView?.transform.ty = 0
            toView?.transform.tx = 0
        } completion: {_ in
            fromViewC.view.transform.ty = 0
            fromViewC.view.transform.tx = 0
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func preparePosition(toView: UIView?, container: UIView){
        switch direction {
        case .up:
            toView?.transform.ty -= container.bounds.height * 0.3
        case .down:
            toView?.transform.ty = container.bounds.height * 0.3
        case .right:
            toView?.transform.tx = container.bounds.width * 0.3
        case .left:
            toView?.transform.tx -= container.bounds.width * 0.3
        }
    }
    
    private func animatePosition(fromView: UIView, container: UIView){
        switch direction {
        case .up:
            fromView.transform.ty += container.bounds.height
        case .down:
            fromView.transform.ty -= container.bounds.height
        case .right:
            fromView.transform.tx -= container.bounds.width
        case .left:
            fromView.transform.tx += container.bounds.width
        }
    }
}


extension UIViewControllerAnimatedTransitioning where Self == EZAppearanceAnimation {
    /// Creates a default appearance animation (fade in, 0.2 seconds).
    ///
    /// ### Example
    /// ```swift
    /// viewController.transitioningDelegate = EZUIViewControllerTransitioningDelegate(
    ///     delegate: nil,
    ///     animation: .ezAppearance
    /// )
    /// ```
    public static var ezAppearance: Self { .init() }
    
    /// Creates a custom appearance animation with specified duration.
    ///
    /// - Parameter duration: The duration of the fade-in animation in seconds.
    /// - Returns: A configured appearance animation.
    ///
    /// ### Example
    /// ```swift
    /// let animation = UIViewControllerAnimatedTransitioning.ezAppearance(duration: 0.5)
    /// ```
    public static func ezAppearance(duration: TimeInterval) -> Self { .init(duration: duration) }
}

/// An animation that fades in a view controller.
///
/// `EZAppearanceAnimation` animates the presentation of a view controller by fading it in
/// from transparent to opaque. The underlying view controller remains visible.
///
/// ### Example: Using in a transition delegate
///
/// ```swift
/// let animation = EZAppearanceAnimation()
/// animation.duration = 0.3
///
/// let delegate = EZUIViewControllerTransitioningDelegate(
///     delegate: nil,
///     animation: animation
/// )
/// viewController.transitioningDelegate = delegate
/// ```
public class EZAppearanceAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    /// The duration of the fade-in animation in seconds.
    ///
    /// Defaults to `0.2` seconds.
    public var duration: TimeInterval = 0.2
    init(duration: TimeInterval? = nil){
        if let duration { self.duration = duration }
    }
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let toViewC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        let container = transitionContext.containerView
        container.addSubview(toViewC.view)
        toViewC.view.frame = transitionContext.finalFrame(for: toViewC)
        toViewC.view.alpha = 0
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext)
        ) {
            toViewC.view.alpha = 1
        } completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

extension UIViewControllerAnimatedTransitioning where Self == EZDisappearanceAnimation {
    /// Creates a default disappearance animation (fade out, 0.2 seconds).
    ///
    /// ### Example
    /// ```swift
    /// viewController.transitioningDelegate = EZUIViewControllerTransitioningDelegate(
    ///     delegate: nil,
    ///     animation: .ezDisappearance
    /// )
    /// ```
    public static var ezDisappearance: Self { .init() }
    
    /// Creates a custom disappearance animation with specified duration.
    ///
    /// - Parameter duration: The duration of the fade-out animation in seconds.
    /// - Returns: A configured disappearance animation.
    ///
    /// ### Example
    /// ```swift
    /// let animation = UIViewControllerAnimatedTransitioning.ezDisappearance(duration: 0.5)
    /// ```
    public static func ezDisappearance(duration: TimeInterval) -> Self { .init(duration: duration) }
}

/// An animation that fades out a view controller.
///
/// `EZDisappearanceAnimation` animates the dismissal of a view controller by fading it out
/// from opaque to transparent. The underlying view controller becomes fully visible.
///
/// ### Example: Using in a transition delegate
///
/// ```swift
/// let animation = EZDisappearanceAnimation()
/// animation.duration = 0.3
///
/// let delegate = EZUIViewControllerTransitioningDelegate(
///     delegate: nil,
///     animation: animation
/// )
/// viewController.transitioningDelegate = delegate
/// ```
public class EZDisappearanceAnimation: NSObject, UIViewControllerAnimatedTransitioning{
    /// The duration of the fade-out animation in seconds.
    ///
    /// Defaults to `0.2` seconds.
    public var duration: TimeInterval = 0.2
    init(duration: TimeInterval? = nil){
        if let duration { self.duration = duration }
    }
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromViewC = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        let toView = transitionContext.view(forKey: .to)
        let container = transitionContext.containerView
        if let toView{
            container.addSubview(toView)
            container.bringSubviewToFront(fromViewC.view)
        }
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseInOut]
        ){
            fromViewC.view.alpha = 0
        } completion: {_ in
            fromViewC.view.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

extension UIViewControllerAnimatedTransitioning where Self == EZShiftAnimation{
    /// Creates a shift animation for transitioning between view controllers.
    ///
    /// - Parameters:
    ///   - direction: The direction of the shift (the new view controller slides in from this direction).
    ///   - duration: The duration of the animation in seconds.
    /// - Returns: A configured shift animation.
    ///
    /// ### Example
    /// ```swift
    /// let animation = UIViewControllerAnimatedTransitioning.ezShift(
    ///     direction: .left,
    ///     duration: 0.3
    /// )
    /// ```
    public static func ezShift(
        direction: EZAnimationDirection,
        duration: TimeInterval = 0.5
    ) -> Self { .init(direction: direction, duration: duration) }
}

/// An animation that shifts between view controllers by sliding them in opposite directions.
///
/// `EZShiftAnimation` animates the transition between two view controllers by sliding the new
/// view controller in from one direction while sliding the old one out in the opposite direction.
/// This creates a "shifting" effect, commonly used in tab bar controllers or page view controllers.
///
/// ### Example: Using in a tab bar delegate
///
/// ```swift
/// let animation = EZShiftAnimation()
/// animation.direction = .left
/// animation.duration = 0.3
///
/// let delegate = EZUITabBarControllerDelegate(
///     delegate: nil,
///     animation: animation
/// )
/// tabBarController.delegate = delegate
/// ```
public class EZShiftAnimation: NSObject, UIViewControllerAnimatedTransitioning{
    /// The duration of the animation in seconds.
    ///
    /// Defaults to `0.5` seconds.
    public var duration: TimeInterval = 0.5
    
    /// The direction from which the new view controller slides in.
    ///
    /// The old view controller slides out in the opposite direction.
    /// Defaults to `.left`.
    public var direction: EZAnimationDirection = .left
    
    
    init(direction: EZAnimationDirection = .up, duration: TimeInterval? = nil){
        self.direction = direction
        if let duration { self.duration = duration }
    }
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let toViewC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        let fromView = transitionContext.view(forKey: .from)
        let container = transitionContext.containerView
        container.addSubview(toViewC.view)
        toViewC.view.frame = transitionContext.finalFrame(for: toViewC)
        
        preparePosition(toView: toViewC.view, container: container)
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0.0,
            options: [.curveEaseInOut]
        ) {
            toViewC.view.transform.ty = 0
            toViewC.view.transform.tx = 0
            self.animatePosition(fromView: fromView, container: container)
        } completion: { _ in
            fromView?.transform.ty = 0
            fromView?.transform.tx = 0
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func preparePosition(toView: UIView, container: UIView){
        switch direction {
        case .up:
            toView.transform.ty = container.bounds.height
        case .down:
            toView.transform.ty = -container.bounds.height
        case .right:
            toView.transform.tx = -container.bounds.width
        case .left:
            toView.transform.tx = container.bounds.width
        }
    }
    
    private func animatePosition(fromView: UIView?, container: UIView){
        switch direction {
        case .up:
            fromView?.transform.ty -= container.bounds.height
        case .down:
            fromView?.transform.ty = container.bounds.height
        case .right:
            fromView?.transform.tx = container.bounds.width
        case .left:
            fromView?.transform.tx -= container.bounds.width
        }
    }
}

#endif
