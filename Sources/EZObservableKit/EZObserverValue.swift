//
//  File.swift
//
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

/// A read-only container describing a single observable change.
///
/// This protocol is used by the observation system to pass both the previous (`old`) and the
/// new (`new`) value to observer callbacks.
///
/// Some notifications may also carry an optional execution `wrapper` describing how the callback
/// should be scheduled or executed.
public protocol EZObserverValueProtocol<Value> {
    associatedtype Value
    /// The value before the change.
    var old: Value { get }
    /// The value after the change.
    var new: Value { get }
    
    /// Optional wrapper describing how the observer callback should be executed.
    var wrapper: EZObserverWrapperProtocol? { get }
}

/// Concrete `Sendable` implementation of `EZObserverValueProtocol`.
///
/// `EZObserverValue` is typically constructed internally by an observable and delivered to
/// observers. It also provides `removeObserver()` which lets an observer unsubscribe using the
/// token captured at subscription time.
///
/// ### Example
/// ```swift
/// _ = $value.add { change in
///     print("old:", change.old)
///     print("new:", change.new)
///
///     // Optionally unsubscribe:
///     // change.removeObserver()
/// }
/// ```
public struct EZObserverValue<Value>: Sendable, EZObserverValueProtocol {
    /// The value before the change.
    nonisolated(unsafe) public let old: Value
    /// The value after the change.
    nonisolated(unsafe) public let new: Value
    /// Optional wrapper describing how the observer callback should be executed.
    public let wrapper: EZObserverWrapperProtocol?
    private let removeObserverAction: @Sendable () -> ()
    
    init(
        old: Value,
        new: Value,
        wrapper: EZObserverWrapperProtocol? = nil,
        removeObserverAction: @Sendable @escaping () -> Void
    ) {
        self.old = old
        self.new = new
        self.wrapper = wrapper
        self.removeObserverAction = removeObserverAction
    }
    
    /// Removes the observer that received this change notification.
    ///
    /// This is a convenience for self-unsubscribing observers.
    public func removeObserver() { removeObserverAction() }
}
