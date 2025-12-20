//
//  File.swift
//
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

/// A lightweight wrapper that controls *how* an observer callback is executed.
///
/// Observables may attach an optional `EZObserverWrapperProtocol` to a change notification.
/// The wrapper can redirect execution into a specific context (e.g. an animation block,
/// a dispatch queue, an actor hop, throttling/debouncing, etc.).
///
/// ### Example: wrapping observer execution in an animation context
/// ```swift
/// struct AnimationWrapper: EZObserverWrapperProtocol {
///     func use(action: @escaping () -> ()) {
///         withAnimation {
///             action()
///         }
///     }
/// }
/// ```
public protocol EZObserverWrapperProtocol: Sendable {
    /// Executes (or schedules) `action` according to the wrapper's policy.
    func use(action: @escaping () -> ())
}
