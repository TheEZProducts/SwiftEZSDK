//
//  EZTransition.swift
//  UIPackkages
//
//  Created by Александр Сенин on 15.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation
import UIKit

/// Protocol for transition context types.
///
/// All transition contexts must conform to this protocol. Contexts contain information
/// about the transition (animation, presentation style, completion handlers, etc.).
public protocol EZTransitionContextProtocol {}

/// Protocol for transition operations.
///
/// Transitions conforming to this protocol can be executed via `transit()`.
/// The context contains all the configuration needed for the transition.
///
/// ### Example
/// ```swift
/// let transition = viewController.ezTransit.present(otherVC)
///     .animation(.coverVertical)
///     .animate()
/// transition.transit()
/// ```
public protocol EZTransitionProtocol<Context>{
    /// The type of context this transition uses.
    associatedtype Context: EZTransitionContextProtocol
    
    /// The context containing transition configuration.
    var context: Context { get set }
    
    /// Executes the transition.
    ///
    /// - Returns: `true` if the transition was successfully initiated, `false` otherwise.
    @MainActor
    @discardableResult
    func transit() -> Bool 
}

/// A wrapper that provides access to transition operations for a container.
///
/// `EZTransition` is a generic struct that wraps a container (like `UIViewController` or `EZContainerView`)
/// and provides a fluent API for creating and executing transitions.
///
/// ### Example: Using with UIViewController
///
/// ```swift
/// let transition = viewController.ezTransit.present(otherVC)
///     .animation(.coverVertical)
///     .animate()
/// transition.transit()
/// ```
///
/// ### Example: Using with EZContainerView
///
/// ```swift
/// let transition = containerView.ezTransit.present(vc)
///     .animate()
/// transition.transit()
/// ```
@MainActor
public struct EZTransition<Container>{
    private(set) var container: Container
}

extension EZTransition<UIViewController>{
    /// Creates a transition wrapper for a view controller.
    ///
    /// - Parameter container: The view controller to wrap.
    public init(_ container: UIViewController) {
        self.container = container
    }
}

extension EZTransition<EZContainerView>{
    /// Creates a transition wrapper for a container view.
    ///
    /// - Parameter container: The container view to wrap.
    public init(_ container: EZContainerView) {
        self.container = container
    }
}
#endif
