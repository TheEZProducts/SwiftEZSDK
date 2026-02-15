//
//  EZCustomTransition.swift
//  EZSDK
//
//  Created by Александр Сенин on 19.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension EZTransition<UIViewController>{
    /// Creates a custom transition that can be configured with a transition controller.
    ///
    /// The transition controller will be searched in the view controller hierarchy.
    ///
    /// - Returns: A custom transition instance.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.custom()
    ///     .transitionType(.ezOpen)
    ///     .animate()
    ///     .transit()
    /// ```
    public func custom() -> EZCustomTransition {
        .init(container: container)
    }
    
    /// Creates a custom transition to a specific view controller.
    ///
    /// - Parameter controller: The target view controller to transition to.
    /// - Returns: A custom transition instance configured to transition to the controller.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.customTo(controller: targetVC)
    ///     .transitionType(.ezToController)
    ///     .animate()
    ///     .transit()
    /// ```
    public func customTo(controller: UIViewController) -> EZCustomTransition {
        .init(container: container, toController: controller)
    }
    
    /// Creates a custom transition to a specific index.
    ///
    /// - Parameter index: The target index to transition to.
    /// - Returns: A custom transition instance configured to transition to the index.
    ///
    /// ### Example
    /// ```swift
    /// let transition = viewController.ezTransit.customTo(index: 2)
    ///     .transitionType(.ezToIndex)
    ///     .animate()
    ///     .transit()
    /// ```
    public func customTo(index: Int) -> EZCustomTransition {
        .init(container: container, toIndex: index)
    }
}

extension EZTransition where Container: EZTransitionControllerProtocol{
    /// Creates a custom transition using the transition controller directly.
    ///
    /// - Returns: A custom transition instance.
    public func custom() -> EZCustomTransition {
        .init(transitionController: container)
    }
    
    /// Creates a custom transition to a specific view controller.
    ///
    /// - Parameter controller: The target view controller to transition to.
    /// - Returns: A custom transition instance.
    public func customTo(controller: UIViewController) -> EZCustomTransition {
        .init(transitionController: container, toController: controller)
    }
    
    /// Creates a custom transition to a specific index.
    ///
    /// - Parameter index: The target index to transition to.
    /// - Returns: A custom transition instance.
    public func customTo(index: Int) -> EZCustomTransition {
        .init(transitionController: container, toIndex: index)
    }
}

/// Protocol for objects that can handle custom transitions.
///
/// Transition controllers implement this protocol to provide custom transition logic
/// based on transition types and contexts.
///
/// ### Example
/// ```swift
/// class MyTransitionController: EZTransitionControllerProtocol {
///     func transit(context: EZCustomTransitionContext) -> Bool {
///         switch context.transitionType {
///         case .ezOpen:
///             // Handle open transition
///             return true
///         default:
///             return false
///         }
///     }
/// }
/// ```
@MainActor
public protocol EZTransitionControllerProtocol: AnyObject {
    /// Executes a custom transition based on the provided context.
    ///
    /// - Parameter context: The transition context containing all transition information.
    /// - Returns: `true` if the transition was handled, `false` otherwise.
    @discardableResult
    func transit(context: EZCustomTransitionContext) -> Bool
}

extension EZTransitionControllerProtocol{
    /// Provides access to transition operations for this transition controller.
    ///
    /// Use this to create transitions that use this controller directly.
    public var transition: EZTransition<Self> { .init(container: self) }
}

/// Protocol for transition controllers that can act as delegates.
///
/// Extends `EZTransitionControllerProtocol` to indicate that the controller can be used
/// as a delegate for other transition controllers.
@MainActor
public protocol EZTransitionControllerDelegateProtocol: EZTransitionControllerProtocol {}

/// Protocol for view controllers that have a transition controller.
///
/// View controllers conforming to this protocol can have a `transitionController` property
/// that handles custom transitions.
@MainActor
public protocol EZTransitionControlledProtocol: AnyObject {
    /// The transition controller that handles custom transitions for this view controller.
    var transitionController: EZTransitionControllerProtocol? { get set }
}

extension EZTransitionControllerProtocol where Self == EZTransitionController {
    /// Creates a transition controller with a custom action closure.
    ///
    /// - Parameter action: A closure that handles transitions based on the context.
    /// - Returns: A transition controller instance.
    ///
    /// ### Example
    /// ```swift
    /// let controller = EZTransitionController.custom { context in
    ///     switch context.transitionType {
    ///     case .ezOpen:
    ///         // Handle open
    ///         return true
    ///     default:
    ///         return false
    ///     }
    /// }
    /// ```
    public static func custom(
        _ action: @MainActor @escaping (_ context: EZCustomTransitionContext) -> Bool
    ) -> Self {
        .init(action)
    }
    
    /// Creates a transition controller that delegates to another controller.
    ///
    /// - Parameter delegate: The delegate controller to forward transitions to.
    /// - Returns: A transition controller instance.
    public static func delegate(
        _ delegate: EZTransitionControllerDelegateProtocol
    ) -> Self {
        .init(delegate)
    }
}

/// A concrete implementation of `EZTransitionControllerProtocol`.
///
/// `EZTransitionController` can be initialized with either an action closure or a delegate.
/// It forwards transitions to the delegate if provided, otherwise uses the action closure.
///
/// ### Example: Using with action closure
///
/// ```swift
/// let controller = EZTransitionController { context in
///     // Handle transition
///     return true
/// }
/// viewController.transitionController = controller
/// ```
///
/// ### Example: Using with delegate
///
/// ```swift
/// class MyDelegate: EZTransitionControllerDelegateProtocol {
///     func transit(context: EZCustomTransitionContext) -> Bool {
///         // Handle transition
///         return true
///     }
/// }
///
/// let delegate = MyDelegate()
/// let controller = EZTransitionController(delegate: delegate)
/// viewController.transitionController = controller
/// ```
open class EZTransitionController: EZTransitionControllerProtocol{
    /// The delegate controller to forward transitions to, if any.
    ///
    /// If provided, transitions are forwarded to this delegate. Otherwise, the `action` closure is used.
    public weak var delegate: EZTransitionControllerDelegateProtocol?
    
    /// The action closure that handles transitions.
    ///
    /// Used when no delegate is provided. Defaults to a closure that returns `false`.
    public var action: @MainActor (_ context: EZCustomTransitionContext) -> Bool = {_ in false}
    
    /// Creates a transition controller with an action closure.
    ///
    /// - Parameter action: A closure that handles transitions. Defaults to a no-op that returns `false`.
    public init(_ action: @MainActor @escaping (_ context: EZCustomTransitionContext) -> Bool = {_ in false}){
        self.action = action
    }
    
    /// Creates a transition controller with a delegate.
    ///
    /// - Parameter delegate: The delegate controller to forward transitions to.
    public init(_ delegate: EZTransitionControllerDelegateProtocol){
        self.delegate = delegate
    }
    
    /// Executes a custom transition based on the provided context.
    ///
    /// Forwards to the delegate if available, otherwise uses the action closure.
    ///
    /// - Parameter context: The transition context.
    /// - Returns: `true` if the transition was handled, `false` otherwise.
    @discardableResult
    open func transit(context: EZCustomTransitionContext) -> Bool {
        delegate?.transit(context: context) ?? action(context)
    }
}

/// A type identifier for custom transitions.
///
/// `EZCustomTransitionType` is used to identify different types of custom transitions.
/// It consists of a string key and optional custom data. Two types are equal if their keys match.
///
/// ### Example: Creating custom transition types
///
/// ```swift
/// let openType = EZCustomTransitionType(key: "open", customData: someData)
/// let closeType = EZCustomTransitionType(key: "close")
///
/// // Use in transition
/// transition.transitionType(openType)
/// ```
public struct EZCustomTransitionType: Equatable {
    /// The unique key identifying this transition type.
    public private(set) var key: String
    
    /// Optional custom data associated with this transition type.
    public private(set) var customData: Any?
    
    /// Creates a transition type with a key and optional custom data.
    ///
    /// - Parameters:
    ///   - key: The unique identifier for this transition type.
    ///   - customData: Optional data to pass with the transition.
    public init(key: String, customData: Any? = nil) {
        self.key = key
        self.customData = customData
    }
    
    /// Equality comparison based on the key.
    ///
    /// Two transition types are equal if their keys match, regardless of custom data.
    public static func == (lhs: Self, rhs: Self) -> Bool{
        lhs.key == rhs.key
    }
}

extension EZCustomTransitionType{
    /// Default transition type.
    public static var ezDefault: Self { .init(key: "ezDefault") }
    
    /// Default transition type with custom data.
    ///
    /// - Parameter customData: Custom data to pass with the transition.
    public static func ezDefault(customData: Any) -> Self { .init(key: "ezDefault", customData: customData) }
    
    /// Transition type for transitioning to a specific controller.
    public static var ezToController: Self { .init(key: "ezToController") }
    
    /// Transition type for transitioning to a specific controller with custom data.
    ///
    /// - Parameter customData: Custom data to pass with the transition.
    public static func ezToController(customData: Any) -> Self { .init(key: "ezToController", customData: customData) }
    
    /// Transition type for transitioning to a specific index.
    public static var ezToIndex: Self { .init(key: "ezToIndex") }
    
    /// Transition type for transitioning to a specific index with custom data.
    ///
    /// - Parameter customData: Custom data to pass with the transition.
    public static func ezToIndex(customData: Any) -> Self { .init(key: "ezToIndex", customData: customData) }
    
    /// Transition type for moving to the next item.
    public static var ezNext: Self { .init(key: "ezNext") }
    
    /// Transition type for moving to the next item with custom data.
    ///
    /// - Parameter customData: Custom data to pass with the transition.
    public static func ezNext(customData: Any) -> Self { .init(key: "ezNext", customData: customData) }
    
    /// Transition type for moving to the previous item.
    public static var ezBack: Self { .init(key: "ezBack") }
    
    /// Transition type for moving to the previous item with custom data.
    ///
    /// - Parameter customData: Custom data to pass with the transition.
    public static func ezBack(customData: Any) -> Self { .init(key: "ezBack", customData: customData) }
    
    /// Transition type for a successful operation.
    public static var ezSuccess: Self { .init(key: "ezSuccess") }
    
    /// Transition type for a successful operation with custom data.
    ///
    /// - Parameter customData: Custom data to pass with the transition.
    public static func ezSuccess(customData: Any) -> Self { .init(key: "ezSuccess", customData: customData) }
    
    /// Transition type for a failed operation.
    public static var ezFail: Self { .init(key: "ezFail") }
    
    /// Transition type for a failed operation with custom data.
    ///
    /// - Parameter customData: Custom data to pass with the transition.
    public static func ezFail(customData: Any) -> Self { .init(key: "ezFail", customData: customData) }
    
    /// Transition type for opening/presenting.
    public static var ezOpen: Self { .init(key: "ezOpen") }
    
    /// Transition type for opening/presenting with custom data.
    ///
    /// - Parameter customData: Custom data to pass with the transition.
    public static func ezOpen(customData: Any) -> Self { .init(key: "ezOpen", customData: customData) }
    
    /// Transition type for closing/dismissing.
    public static var ezClose: Self { .init(key: "ezClose") }
    
    /// Transition type for closing/dismissing with custom data.
    ///
    /// - Parameter customData: Custom data to pass with the transition.
    public static func ezClose(customData: Any) -> Self { .init(key: "ezClose", customData: customData) }
}

/// Strategy for searching for a transition controller delegate in the view controller hierarchy.
///
/// Used to determine where to look for a transition controller when executing custom transitions.
public enum EZTransitionControllerDelegateSearchType{
    /// Search only in the controller itself.
    case selfDelegate
    
    /// Search in the controller's parent.
    case parent
    
    /// Search the entire view controller hierarchy (self, parent, presenting, etc.).
    case hierarchy
    
    /// Searches for a transition controller based on this strategy.
    ///
    /// - Parameter controller: The view controller to search from.
    /// - Returns: The found transition controller, or `nil` if not found.
    @MainActor
    public func search(to controller: UIViewController) -> EZTransitionControllerProtocol? {
        switch self {
        case .selfDelegate:
            return (controller as? EZTransitionControlledProtocol)?.transitionController
        case .parent:
            return (controller.ezSourceViewController as? any EZTransitionControlledProtocol)?.transitionController
        case .hierarchy:
            return controller.ezFirstTransitionController
        }
    }
}


//MARK: - EZNavigationTransitionContext
/// Context containing all information needed for a custom transition.
///
/// `EZCustomTransitionContext` holds the configuration and state for custom transitions,
/// including source/target controllers, animation settings, and transition type.
///
/// ### Example: Using in a transition controller
///
/// ```swift
/// func transit(context: EZCustomTransitionContext) -> Bool {
///     switch context.transitionType {
///     case .ezOpen:
///         // Handle open transition
///         if let toController = context.toController {
///             present(toController, animated: context.animate)
///             return true
///         }
///     default:
///         return false
///     }
/// }
/// ```
public struct EZCustomTransitionContext: EZTransitionContextProtocol{
    /// The transition controller to use for this transition.
    ///
    /// If `nil`, the controller will be searched based on `transitionDelegateSearchType`.
    public var transitionController: EZTransitionControllerProtocol?
    
    /// The source view controller (where the transition starts).
    public var fromController: UIViewController?
    
    /// The target view controller (where the transition goes).
    public var toController: UIViewController?
    
    /// The target index (for index-based transitions).
    public var toIndex: Int?
    
    /// Custom data to pass with the transition.
    ///
    /// Can be used to pass additional information specific to your transition logic.
    public var customData: Any?
    
    /// Whether to allow transitions during other transitions.
    ///
    /// If `false`, the transition will be blocked if another transition is in progress.
    public var unsafeTransition: Bool = false
    
    /// The type of transition to perform.
    ///
    /// Used by transition controllers to determine how to handle the transition.
    public var transitionType: EZCustomTransitionType = .ezDefault
    
    /// Strategy for searching for a transition controller.
    ///
    /// Determines where to look for a transition controller if `transitionController` is `nil`.
    public var transitionDelegateSearchType: EZTransitionControllerDelegateSearchType = .hierarchy
    
    /// Whether the transition should be animated.
    public var animate: Bool = false
    
    /// Custom animation to use for the transition.
    ///
    /// If provided, this animation will be used instead of the default.
    public var animation: UIViewControllerAnimatedTransitioning?
    
    /// The modal transition style to use.
    ///
    /// Used for modal presentations.
    public var transitionStyle: UIModalTransitionStyle?
    
    /// The modal presentation style to use.
    ///
    /// Used for modal presentations.
    public var presentationStyle: UIModalPresentationStyle?
    
    /// A closure to execute after the transition completes.
    public var completion: (() -> Void)?
}

extension EZTransitionProtocol where Context == EZCustomTransitionContext{
    /// Sets custom data to pass with the transition.
    ///
    /// - Parameter value: The custom data to pass.
    /// - Returns: A new transition instance with the custom data set.
    public func customData(_ value: Any) -> Self {
        var new = self
        new.context.customData = value
        return new
    }
    
    /// Sets whether the transition should be safe (blocked during other transitions).
    ///
    /// - Parameter value: `true` to block during other transitions, `false` to allow.
    /// - Returns: A new transition instance with the safety setting.
    public func safeTransition(_ value: Bool) -> Self {
        var new = self
        new.context.unsafeTransition = !value
        return new
    }
    
    /// Marks the transition as unsafe (allows during other transitions).
    ///
    /// - Returns: A new transition instance marked as unsafe.
    public func unsafeTransition() -> Self {
        var new = self
        new.context.unsafeTransition = true
        return new
    }
    
    /// Sets the transition type.
    ///
    /// - Parameter value: The transition type to use.
    /// - Returns: A new transition instance with the type set.
    public func transitionType(_ value: EZCustomTransitionType) -> Self{
        var new = self
        new.context.transitionType = value
        return new
    }
    
    /// Sets the strategy for searching for a transition controller.
    ///
    /// - Parameter value: The search strategy to use.
    /// - Returns: A new transition instance with the search strategy set.
    public func transitionDelegateSearchType(_ value: EZTransitionControllerDelegateSearchType) -> Self{
        var new = self
        new.context.transitionDelegateSearchType = value
        return new
    }
    
    /// Sets the modal presentation style.
    ///
    /// - Parameter value: The presentation style to use.
    /// - Returns: A new transition instance with the presentation style set.
    public func presentationStyle(_ value: UIModalPresentationStyle) -> Self{
        var new = self
        new.context.presentationStyle = value
        return new
    }
    
    /// Sets the modal transition style and enables animation.
    ///
    /// - Parameter value: The transition style to use.
    /// - Returns: A new transition instance with animation enabled and the style set.
    public func animation(_ value: UIModalTransitionStyle) -> Self{
        var new = animate()
        new.context.transitionStyle = value
        return new
    }
    
    /// Sets a custom animation and enables animation.
    ///
    /// - Parameter value: The animation to use.
    /// - Returns: A new transition instance with animation enabled and the animation set.
    public func animation(_ value: UIViewControllerAnimatedTransitioning) -> Self{
        var new = animate()
        new.context.animation = value
        return new
    }
    
    /// Enables animation for the transition.
    ///
    /// - Returns: A new transition instance with animation enabled.
    public func animate() -> Self{
        var new = self
        new.context.animate = true
        return new
    }
    
    /// Sets a completion handler to execute after the transition.
    ///
    /// - Parameter value: The completion closure to execute.
    /// - Returns: A new transition instance with the completion handler set.
    public func completion(_ value: @escaping () -> Void) -> Self{
        var new = self
        new.context.completion = value
        return new
    }
}

protocol EZCustomTransitionProtocol: EZTransitionProtocol<EZCustomTransitionContext>{}

@available(iOS 13.0, tvOS 13.0, *)
extension EZTransitionProtocol<EZCustomTransitionContext>{
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
            let transition = completion {[completion = context.completion] in
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
/// A custom transition that can be configured with various options.
///
/// `EZCustomTransition` provides a flexible way to perform transitions based on transition types
/// and contexts. It searches for a transition controller in the view controller hierarchy and
/// delegates the actual transition logic to it.
///
/// ### Example: Basic custom transition
///
/// ```swift
/// let transition = viewController.ezTransit.custom()
///     .transitionType(.ezOpen)
///     .animate()
///     .transit()
/// ```
///
/// ### Example: Transition to specific controller
///
/// ```swift
/// let transition = viewController.ezTransit.customTo(controller: targetVC)
///     .transitionType(.ezToController)
///     .animation(EZOpenAnimation.ezOpen(direction: .right))
///     .transit()
/// ```
public struct EZCustomTransition: EZTransitionProtocol{
    /// The transition context containing all configuration.
    public var context: EZCustomTransitionContext
    
    /// Creates a custom transition from a view controller.
    ///
    /// - Parameters:
    ///   - container: The source view controller.
    ///   - toController: Optional target view controller.
    public init(
        container: UIViewController,
        toController: UIViewController? = nil
    ) {
        self.context = .init(fromController: container, toController: toController)
    }
    
    /// Creates a custom transition using a transition controller directly.
    ///
    /// - Parameters:
    ///   - transitionController: The transition controller to use.
    ///   - toController: Optional target view controller.
    public init(
        transitionController: EZTransitionControllerProtocol,
        toController: UIViewController? = nil
    ) {
        self.context = .init(transitionController: transitionController, toController: toController)
    }
    
    /// Creates a custom transition from a view controller to a specific index.
    ///
    /// - Parameters:
    ///   - container: The source view controller.
    ///   - toIndex: Optional target index.
    @_disfavoredOverload
    public init(
        container: UIViewController,
        toIndex: Int? = nil
    ) {
        self.context = .init(fromController: container, toIndex: toIndex)
    }
    
    /// Creates a custom transition using a transition controller to a specific index.
    ///
    /// - Parameters:
    ///   - transitionController: The transition controller to use.
    ///   - toIndex: Optional target index.
    @_disfavoredOverload
    public init(
        transitionController: EZTransitionControllerProtocol,
        toIndex: Int? = nil
    ) {
        self.context = .init(transitionController: transitionController, toIndex: toIndex)
    }
    
    /// Executes the custom transition.
    ///
    /// Searches for a transition controller based on `transitionDelegateSearchType` and
    /// delegates the transition to it.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        if let transitionController = context.transitionController{
            return transitionController.transit(context: context)
        }else if let fromController = context.fromController{
            return context.transitionDelegateSearchType
                .search(to: fromController)?
                .transit(context: context) ?? false
        }else {
            return false
        }
    }
}
#endif
