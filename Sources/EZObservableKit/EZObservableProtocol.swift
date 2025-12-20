//
//  EZObservableProtocol.swift
//  EZSDK
//
//  Created by Александр Сенин on 19.12.2025.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

import EZAsyncKit
import EZHelpersKit

/// Common interface for observable values.
///
/// Types conforming to `EZObservableProtocol` expose:
/// - a read-only `wrappedValue`,
/// - subscription APIs that return an `EZObserverToken`,
/// - and utility helpers for signaling and removing observers.
///
/// This protocol is used by both the backing storage and the projected `$property` view of observables.
public protocol EZObservableProtocol<Value> {
    associatedtype Value
    
    /// Current value (read-only view).
    var wrappedValue: Value { get }
    
    /// Adds an observer and returns a token that keeps the subscription alive.
    ///
    /// - Parameters:
    ///   - wrapper: Optional execution wrapper used to run the observer callback.
    ///   - action: Called for each emitted change.
    ///   - removeAction: Optional callback invoked when the observer is removed.
    ///
    /// ### Example
    /// ```swift
    /// let token = $value.add(wrapper: nil) { change in
    ///     print(change.old, "→", change.new)
    /// } removeAction: { _ in
    ///     print("removed")
    /// }
    /// _ = token
    /// ```
    @discardableResult
    func add(
        wrapper: EZObserverWrapperProtocol?,
        action: @Sendable @escaping (EZObserverValue<Value>) -> (),
        removeAction: (@Sendable (EZObserverValue<Value>) -> ())?
    ) -> EZObserverToken<Value>
    
    /// Adds an observer whose callbacks are executed with the specified actor isolation when possible.
    ///
    /// If `isolation` is `nil`, implementations typically fall back to an unsafe isolation variant.
    ///
    /// ### Example
    /// ```swift
    /// _ = $value.addWithIsolation(isolation: MainActor.shared, wrapper: nil) { _ in
    ///     // handled on the main actor
    /// } removeAction: nil
    /// ```
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func addWithIsolation(
        isolation: (any Actor)?,
        wrapper: EZObserverWrapperProtocol?,
        action: @escaping (EZObserverValue<Value>) -> (),
        removeAction: ((EZObserverValue<Value>) -> ())?
    ) -> EZObserverToken<Value>
    
    /// Adds an observer without enforcing actor isolation.
    ///
    /// This is intended for legacy/pre-concurrency contexts where the callback cannot be expressed
    /// as `Sendable` under strict checking.
    @discardableResult
    func addWithUnsafeIsolation(
        wrapper: EZObserverWrapperProtocol?,
        action: @escaping (EZObserverValue<Value>) -> (),
        removeAction: ((EZObserverValue<Value>) -> ())?
    ) -> EZObserverToken<Value>
    
    /// Type-erased variant of `add(...)` that delivers `any EZObserverValueProtocol<Value>`.
    @discardableResult
    func unknownAdd(
        wrapper: EZObserverWrapperProtocol?,
        action: @Sendable @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol
    
    /// Type-erased variant of `addWithIsolation(...)`.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    func unknownAddWithIsolation(
        isolation: (any Actor)?,
        wrapper: EZObserverWrapperProtocol?,
        action: @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol
    
    /// Type-erased variant of `addWithUnsafeIsolation(...)`.
    @discardableResult
    func unknownAddWithUnsafeIsolation(
        wrapper: EZObserverWrapperProtocol?,
        action: @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol
    
    /// Emits a notification using `type` without necessarily changing the stored value.
    ///
    /// - Returns: `self` for fluent chaining.
    @discardableResult
    func signal(_ type: EZSetType) -> Self
    
    /// Removes an observer/subscription by its identifier.
    ///
    /// - Returns: `self` for fluent chaining.
    @discardableResult
    func remove(id: UInt) -> Self
}


extension EZObservableProtocol {
    /// Creates a derived observable by mapping each emitted value.
    ///
    /// The returned `EZObservable<NewValue>` is updated whenever this observable emits a change.
    ///
    /// - Parameters:
    ///   - wrapper: Optional wrapper that may control how the internal subscription callback runs.
    ///   - handler: Mapping closure from the current `Value` to `NewValue`.
    ///
    /// ### Example
    /// ```swift
    /// let length: EZObservable<Int> = $text.handler { $0.count }
    /// $length.add { change in
    ///     print("length:", change.new)
    /// }
    /// ```
    public func handler<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        handler: @Sendable @escaping (Value) -> (NewValue)
    ) -> EZObservable<NewValue> {
        let hand = EZObserversStorage(value: handler(wrappedValue))
        let token = add(wrapper: nil) {[weak hand] in
            hand?.set(value: handler($0.new), .common)
        } removeAction: {_ in}
        hand.setAnchor(token.anchorObject)
        return .init(storage: hand)
    }
}


extension EZObservableProtocol where Value: Hashable & Sendable {
    /// Creates a derived observable by mapping the current value through a lookup table.
    ///
    /// - Parameters:
    ///   - wrapper: Optional wrapper passed through to the derived observable.
    ///   - defaultValue: Fallback value when the key is not present in `map`. If `nil`, the first
    ///     value from `map` is used.
    ///   - map: Lookup table from `Value` to `NewValue`.
    /// - Returns: A derived observable, or `nil` when `map` is empty.
    ///
    /// ### Example
    /// ```swift
    /// let statusText = $status.switcher([0: "idle", 1: "busy"], defaultValue: "unknown")
    /// statusText?.add { print($0.new) }
    /// ```
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        defaultValue: NewValue? = nil,
        _ map: [Value: NewValue]
    ) -> EZObservable<NewValue>? {
        if map.count == 0 { return nil }
        let map = EZUnsafeSendableWrapper(map)
        let defaultValue = EZUnsafeSendableWrapper(defaultValue ?? map.value.first!.value)
        return handler(wrapper: wrapper) {
            (map.value[$0] ?? defaultValue.value)
        }
    }
}

extension EZObservableProtocol where Value == Int {
    /// Creates a derived observable by using the current `Int` as an index into an array.
    ///
    /// - Parameters:
    ///   - wrapper: Optional wrapper passed through to the derived observable.
    ///   - defaultValue: Fallback when the index is out of bounds. If `nil`, the first element of `map` is used.
    ///   - map: Array of values indexed by the current `Int`.
    /// - Returns: A derived observable, or `nil` when `map` is empty.
    ///
    /// ### Example
    /// ```swift
    /// let label = $index.switcher(["zero", "one", "two"], defaultValue: "?")
    /// _ = label?.add { print($0.new) }
    /// ```
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        defaultValue: NewValue? = nil,
        _ map: [NewValue]
    ) -> EZObservable<NewValue>? {
        if map.count == 0 {return nil}
        let map = EZUnsafeSendableWrapper(map)
        let defaultValue = EZUnsafeSendableWrapper(defaultValue ?? map.value.first!)
        return handler(wrapper: wrapper) { map.value[ezSafe: $0] ?? defaultValue.value }
    }
    
    /// Convenience overload that accepts the mapping values as variadic arguments.
    ///
    /// ### Example
    /// ```swift
    /// let label = $index.switcher("zero", "one", "two")
    /// _ = label?.add { print($0.new) }
    /// ```
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        defaultValue: NewValue? = nil,
        _ map: NewValue...
    ) -> EZObservable<NewValue>? {
        switcher(wrapper: wrapper, defaultValue: defaultValue, map)
    }
}

extension EZObservableProtocol where Value == Bool {
    /// Creates a derived observable by choosing between two values based on the current `Bool`.
    ///
    /// ### Example
    /// ```swift
    /// let title = $isEnabled.switcher("Enabled", "Disabled")
    /// _ = $title.add { print($0.new) }
    /// ```
    public func switcher<NewValue>(
        wrapper: EZObserverWrapperProtocol? = nil,
        _ tValue: NewValue,
        _ fValue: NewValue
    ) -> EZObservable<NewValue> {
        let tValue = EZUnsafeSendableWrapper(tValue)
        let fValue = EZUnsafeSendableWrapper(fValue)
        return handler(wrapper: wrapper) { $0 ? tValue.value : fValue.value }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension EZObservableProtocol {
    /// Bridges observation into an `AsyncStream` of change events.
    ///
    /// The stream yields `EZObserverValue<Value>` for every emitted event and finishes when the
    /// underlying subscription is removed.
    ///
    /// - Parameters:
    ///   - wrapper: Optional wrapper controlling how the internal observer callback is executed.
    ///   - result: Receives the created subscription token.
    /// - Returns: An `AsyncStream` of change events.
    ///
    /// ### Example
    /// ```swift
    /// let stream = $value.makeStream { token in
    ///     _ = token
    /// }
    ///
    /// for await change in stream {
    ///     print(change.new)
    /// }
    /// ```
    public func makeStream(
        wrapper: EZObserverWrapperProtocol? = nil,
        result: (EZObserverToken<Value>) -> () = {_ in}
    ) -> AsyncStream<EZObserverValue<Value>> {
        let (stream, continuation) = AsyncStream<EZObserverValue<Value>>.makeStream()
        let resultValue = add(wrapper: wrapper) { value in
            continuation.yield(value)
        } removeAction: { _ in
            continuation.finish()
        }
        result(resultValue)
        return stream
    }
}
