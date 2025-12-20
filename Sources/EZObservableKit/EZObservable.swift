//
//  File.swift
//
//
//  Created by Александр Сенин on 28.05.2023.
//

import Foundation
#if canImport(Combine)
import Combine
#endif

import EZAsyncKit
import EZHelpersKit
import EZMacrosKit

/// Property macro that turns a stored property into an observable, `Sendable`‑friendly field.
///
/// The macro expands the property into:
/// - a computed property that forwards `wrappedValue`,
/// - a `$property` projection that exposes subscription helpers,
/// - and a `let _property` backing storage of type `EZObservable<Value>`.
///
/// The optional `defaultWrapper` is forwarded into the backing storage initializer and will be used
/// when a subscription does not provide an explicit wrapper.
///
/// Use `$name` primarily for reading/subscribing and `_name` for mutations.
///
/// ### Example
/// ```swift
/// final class Example: Sendable {
///     @EZObservable public internal(set) var text: String = "Hello"
///
///     func start() {
///         $text.add { change in
///             print(change.old, "→", change.new)
///         }
///     }
///
///     func setText(_ newValue: String) {
///         _text.set(value: newValue)              // emits `.common`
///         _text.set(value: newValue, .silent)     // updates without notifying
///     }
/// }
/// ```
@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZObservable(
    defaultWrapper: EZObserverWrapperProtocol? = nil
) = #externalMacro(module: "EZMacros", type: "EZConstantPropertyWrapperMacro")

/// Generic form of `@EZObservable` that spells the value type explicitly.
///
/// ### Example
/// ```swift
/// @EZObservable<String> public internal(set) var text = "Hello"
/// ```
@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZObservable<T>(
    defaultWrapper: EZObserverWrapperProtocol? = nil
) = #externalMacro(module: "EZMacros", type: "EZConstantPropertyWrapperMacro")

/// Observable value container used as backing storage for the `@EZObservable` macro.
///
/// `EZObservable` stores a value and a set of observers. Mutations may emit change events
/// containing `old` and `new` values.
///
/// Notification behavior is controlled by `EZSetType`:
/// - `.common` emits a regular change event,
/// - `.silent` updates the value without notifying observers,
/// - `.changeWrapper(w)` emits the event but overrides the execution wrapper for *this* emission.
///
/// In typical macro usage:
/// - Use `$name` (projected value) for reading/subscribing.
/// - Use `_name` (backing storage) for mutations/subscribing (`set`, `update`, `signal`).
///
/// ### Example: subscribe + mutate
/// ```swift
/// final class Example: Sendable {
///     @EZObservable var count: Int = 0
///
///     func observe() {
///         $count.add { change in
///             print("count:", change.new)
///         }
///     }
///
///     func inc() {
///         _count.update { access in
///             access.value += 1
///         }
///     }
/// }
/// ```
public struct EZObservable<Value>: EZConstantPropertyWrapperProtocol, EZObservableProtocol, Sendable {
    private(set) var storage: EZObserversStorage<Value>
    
    /// Access to the stored value.
    ///
    /// Setting `wrappedValue` assigns the value using `.common` (i.e. notifies observers).
    /// If you need explicit control over notification behavior, use `_property.set(value:_:)`
    /// or `_property.update(type:_:)`.
    public var wrappedValue: Value {
        nonmutating set(value) { storage.set(value: value, .common) }
        get { storage.get() }
    }
    
    /// Projected value (`$property`) intended for reading and subscribing.
    ///
    /// The projected value exposes the subscription API and read/derive helpers.
    /// Mutations should be done through the backing `_property` wrapper.
    public var projectedValue: Projection {
        get { .init(observable: self) }
    }
    
    /// Creates an observable with an initial value.
    ///
    /// - Parameter defaultWrapper: Optional default wrapper used for subscriptions when a wrapper
    ///   is not provided.
    ///
    /// ### Example
    /// ```swift
    /// var value = EZObservable(wrappedValue: 1)
    /// _ = value.add { print($0.new) }
    /// value.set(value: 2)
    /// ```
    public init(wrappedValue: Value, defaultWrapper: EZObserverWrapperProtocol? = nil) {
        self.storage = EZObserversStorage(value: wrappedValue, defaultWrapper: defaultWrapper)
    }
    
    init(storage: EZObserversStorage<Value>) {
        self.storage = storage
    }
    
    /// Makes this observable share the same underlying storage as `observable`.
    ///
    /// After attaching, both observables refer to the same value and observers.
    ///
    /// - Important: This is `mutating` and therefore requires a `var` instance. When `EZObservable`
    ///   is used as a constant backing storage produced by the macro (`let _name`), you cannot call
    ///   `attach` on that backing field.
    ///
    /// ### Example
    /// ```swift
    /// var a = EZObservable(wrappedValue: 1)
    /// var b = EZObservable(wrappedValue: 0)
    /// b.attach(a)
    /// ```
    @discardableResult
    public mutating func attach(_ observable: EZObservable<Value>) -> Self {
        storage = observable.storage
        return self
    }
    
    /// Same as `attach(_:)`, but takes a projected value (`$property`).
    @discardableResult
    public mutating func attach(_ observable: EZObservable<Value>.Projection) -> Self {
        storage = observable._mainObservable.storage
        return self
    }
    
    /// Sets the value and notifies observers according to `type`.
    ///
    /// Returns `self` to allow fluent chaining.
    ///
    /// ### Example
    /// ```swift
    /// _value.set(value: 10)                 // notifies observers
    /// _value.set(value: 10, .silent)        // updates without notifications
    /// _value.set(value: 10, .changeWrapper(MyWrapper()))
    /// // ^ delivers this event using a different wrapper (e.g. animation context)
    /// ```
    @discardableResult
    public func set(value: Value, _ type: EZSetType = .common) -> Self {
        storage.set(value: value, type)
        return self
    }
    
    /// Performs an atomic read/modify/write under the same lock and returns `closure`'s result.
    ///
    /// Use this for compound mutations so the whole operation happens as a single critical section.
    ///
    /// ### Example
    /// ```swift
    /// let old = _value.update { access in
    ///     let old = access.value
    ///     access.value = old + 1
    ///     return old
    /// }
    /// _ = old
    /// ```
    @discardableResult
    public func update<R>(type: EZSetType = .common, _ closure: (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R {
        try storage.update(type: type, closure)
    }
    
    /// Emits a notification using `type` without changing the stored value.
    ///
    /// This re-emits the current value as an event (effectively `old == new == current`).
    ///
    /// Returns `self` to allow fluent chaining.
    ///
    /// ### Example
    /// ```swift
    /// _value.signal()                         // notify observers with the current value
    /// _value.signal(.silent)                  // no-op for observers
    /// _value.signal(.changeWrapper(MyWrapper()))
    /// // ^ re-emit but run callbacks via a different wrapper for this emission
    /// ```
    @discardableResult
    public func signal(_ type: EZSetType = .common) -> Self {
        storage.signal(type)
        return self
    }
    
    /// Removes a single observer/subscription by its identifier.
    ///
    /// - Returns: `self` for fluent chaining.
    @discardableResult
    public func remove(id: UInt) -> Self { storage.remove(id: id); return self }
    
    /// Removes all observers/subscriptions.
    ///
    /// - Returns: `self` for fluent chaining.
    @discardableResult
    public func removeAll() -> Self { storage.removeAll(); return self }
    
    /// Breaks the dependency on a *parent* observable created by derived helpers (e.g. `handler` / `switcher`).
    ///
    /// Some helper APIs create a derived `EZObservable` by internally subscribing it to a parent observable.
    /// To keep that internal subscription alive, the derived storage may keep a parent/anchor reference.
    ///
    /// Calling `breakParentDependansy()` detaches the derived observable from that parent linkage.
    /// This is an advanced escape hatch for cases where you want the derived observable to stop being
    /// coupled to the parent’s lifetime / propagation.
    ///
    /// Note: this does not remove *your* observers. It only breaks the internal parent dependency.
    ///
    /// ### Example: detach a derived observable
    /// ```swift
    /// let length = $text.handler { $0.count }   // derived EZObservable<Int>
    /// _ = $length.add { print("length:", $0.new) }
    ///
    /// // Later you can detach it from the parent (`text`) if needed:
    /// length.breakParentDependansy()
    /// ```
    @discardableResult
    public func breakParentDependansy() -> Self { storage.breakParentDependansy(); return self }
}

extension EZObservable {
    /// Adds an observer and returns a token that keeps the subscription alive.
    ///
    /// - Parameters:
    ///   - wrapper: Optional wrapper controlling how the callback is executed.
    ///     If `nil`, the storage's `defaultWrapper` (if any) is used.
    ///   - action: Called for each emitted change.
    ///   - removeAction: Optional callback invoked when the observer is removed.
    ///
    /// ### Example
    /// ```swift
    /// let token = _value.add { change in
    ///     print(change.old, "→", change.new)
    /// }
    /// _ = token
    /// ```
    @discardableResult
    public func add(
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @Sendable @escaping (EZObserverValue<Value>) -> (),
        removeAction: (@Sendable (EZObserverValue<Value>) -> ())? = nil
    ) -> EZObserverToken<Value> {
        storage.add(wrapper: wrapper, action: action, removeAction: removeAction)
    }
    
    /// Adds an observer whose callbacks are executed with the specified actor isolation when possible.
    ///
    /// If `isolation` is `nil`, this falls back to `addWithUnsafeIsolation`.
    ///
    /// ### Example
    /// ```swift
    /// _value.addWithIsolation(isolation: MainActor.shared) { _ in
    ///     // runs on the main actor
    /// }
    /// ```
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public func addWithIsolation(
        isolation: (any Actor)? = #isolation,
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @escaping (EZObserverValue<Value>) -> (),
        removeAction: ((EZObserverValue<Value>) -> ())? = nil
    ) -> EZObserverToken<Value> {
        if let isolation {
            add(
                wrapper: wrapper,
                action: wrappAction(isolation: isolation, action: action),
                removeAction: removeAction.map { wrappAction(isolation: isolation, action: $0) }
            )
        } else {
            addWithUnsafeIsolation(
                wrapper: wrapper,
                action: action,
                removeAction: removeAction
            )
        }
    }
    
    /// Adds an observer without enforcing actor isolation.
    ///
    /// This is intended for legacy/pre-concurrency contexts where the callback cannot be expressed
    /// as `Sendable` under strict checking.
    @discardableResult
    public func addWithUnsafeIsolation(
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @escaping (EZObserverValue<Value>) -> (),
        removeAction: ((EZObserverValue<Value>) -> ())? = nil
    ) -> EZObserverToken<Value> {
        let action = EZUnsafeSendableWrapper(action)
        let removeAction: (@Sendable (EZObserverValue<Value>) -> ())? = removeAction.map {
            let action = EZUnsafeSendableWrapper($0)
            return { action.value($0) }
        }
        return storage.add(
            wrapper: wrapper,
            action: { action.value($0) },
            removeAction: removeAction
        )
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    private func wrappAction(
        isolation: (any Actor),
        action: @escaping (EZObserverValue<Value>) -> ()
    ) -> @Sendable (EZObserverValue<Value>) -> () {
        if #available(macOS 26.0, iOS 26.0, watchOS 26.0, visionOS 26.0, tvOS 26.0, *) {
            let action = EZUnsafeSendableWrapper(action)
            return { value in
                isolation.ezTaskImmediate { _ in action.value(value) }
            }
        } else {
            let isoletedAction = EZActorIsolator(isolation: isolation, value: action)
            if isolation is MainActor {
                return { value in
                    if Thread.isMainThread {
                        isoletedAction.unsafeUpdate { $0(value) }
                    }else{
                        isoletedAction.update { $0(value) }
                    }
                }
            } else {
                return { value in
                    isoletedAction.update { $0(value) }
                }
            }
        }
    }
}

extension EZObservable {
    /// Type-erased variant of `add(...)` that accepts `any EZObserverValueProtocol<Value>`.
    @discardableResult
    public func unknownAdd(
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @Sendable @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol{
        add(wrapper: wrapper) { action($0) }
    }
    
    /// Type-erased variant of `addWithIsolation(...)`.
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    @discardableResult
    public func unknownAddWithIsolation(
        isolation: (any Actor)? = #isolation,
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol {
        addWithIsolation(
            isolation: isolation,
            wrapper: wrapper,
            action: action
        )
    }
    
    /// Type-erased variant of `addWithUnsafeIsolation(...)`.
    @discardableResult
    public func unknownAddWithUnsafeIsolation(
        wrapper: EZObserverWrapperProtocol? = nil,
        action: @escaping (any EZObserverValueProtocol<Value>) -> ()
    ) -> EZObserverTokenProtocol {
        addWithUnsafeIsolation(
            wrapper: wrapper,
            action: action
        )
    }
}


@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZObservableProjection() = #externalMacro(module: "EZMacros", type: "EZConstantPropertyWrapperMacro")

@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZObservableProjection<T>() = #externalMacro(module: "EZMacros", type: "EZConstantPropertyWrapperMacro")

public typealias EZObservableProjection<Value> = EZObservable<Value>.Projection

extension EZObservable {
    /// Projected value exposed as `$property`.
    ///
    /// This is a read-focused view used to:
    /// - read the current value (`wrappedValue`),
    /// - subscribe to changes (`add...`),
    /// - compute derived results under the same lock (`update(type:_:)`).
    ///
    /// Note: `update` here receives a plain `Value` (by value). For value types it does not replace
    /// the stored value; for mutations use the backing `_property.update` / `_property.set` APIs.
    public struct Projection: EZObservableProtocol, EZConstantPropertyWrapperProtocol, Sendable {
        let _mainObservable: EZObservable<Value>
        
        /// Read-only access to the current stored value.
        ///
        /// ### Example
        /// ```swift
        /// let current = $value.wrappedValue
        /// ```
        public var wrappedValue: Value {
            _read { yield _mainObservable.wrappedValue }
            nonmutating set {}
        }
        
        public var projectedValue: Projection { self }
        
        /// Computes a derived result under the same lock by passing the current value into `closure`.
        ///
        /// The default `type` is `.silent` to avoid emitting notifications for derived reads.
        ///
        /// ### Example
        /// ```swift
        /// let length = $text.update { $0.count }
        /// ```
        @discardableResult
        public func update<R>(type: EZSetType = .silent, _ closure: (Value) throws -> (R)) rethrows -> R {
            try _mainObservable.update(type: type) { try closure($0.value) }
        }
        
        /// Adds an observer and returns a token that keeps the subscription alive.
        ///
        /// - Parameters:
        ///   - wrapper: Optional wrapper controlling how the callback is executed.
        ///     If `nil`, the observable's default wrapper (if any) is used.
        ///   - action: Called for each emitted change.
        ///   - removeAction: Optional callback invoked when the observer is removed.
        ///
        /// ### Example
        /// ```swift
        /// let token = $value.add { change in
        ///     print(change.old, "→", change.new)
        /// }
        /// _ = token
        /// ```
        @discardableResult
        public func add(
            wrapper: (any EZObserverWrapperProtocol)? = nil,
            action: @escaping @Sendable (EZObserverValue<Value>) -> (),
            removeAction: (@Sendable (EZObserverValue<Value>) -> ())? = nil
        ) -> EZObserverToken<Value> {
            _mainObservable.add(
                wrapper: wrapper,
                action: action,
                removeAction: removeAction
            )
        }
        
        /// Adds an observer whose callbacks are executed with the specified actor isolation when possible.
        ///
        /// If `isolation` is `nil`, this falls back to `addWithUnsafeIsolation`.
        ///
        /// ### Example
        /// ```swift
        /// $value.addWithIsolation(isolation: MainActor.shared) { _ in
        ///     // runs on the main actor when supported
        /// }
        /// ```
        @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
        @discardableResult
        public func addWithIsolation(
            isolation: (any Actor)? = #isolation,
            wrapper: (any EZObserverWrapperProtocol)? = nil,
            action: @escaping (EZObserverValue<Value>) -> (),
            removeAction: ((EZObserverValue<Value>) -> ())? = nil
        ) -> EZObserverToken<Value> {
            _mainObservable.addWithIsolation(
                isolation: isolation,
                wrapper: wrapper,
                action: action,
                removeAction: removeAction
            )
        }
        
        /// Adds an observer without enforcing actor isolation.
        ///
        /// This is intended for legacy/pre-concurrency contexts where the callback cannot be expressed
        /// as `Sendable` under strict checking.
        ///
        /// ### Example
        /// ```swift
        /// $value.addWithUnsafeIsolation { change in
        ///     print(change.new)
        /// }
        /// ```
        @discardableResult
        public func addWithUnsafeIsolation(
            wrapper: (any EZObserverWrapperProtocol)? = nil,
            action: @escaping (EZObserverValue<Value>) -> (),
            removeAction: ((EZObserverValue<Value>) -> ())? = nil
        ) -> EZObserverToken<Value> {
            _mainObservable.addWithUnsafeIsolation(
                wrapper: wrapper,
                action: action,
                removeAction: removeAction
            )
        }
        
        /// Type-erased variant of `add(...)` that delivers `any EZObserverValueProtocol<Value>`.
        ///
        /// ### Example
        /// ```swift
        /// _ = $value.unknownAdd { change in
        ///     print(change.new)
        /// }
        /// ```
        @discardableResult
        public func unknownAdd(
            wrapper: (any EZObserverWrapperProtocol)? = nil,
            action: @escaping @Sendable (any EZObserverValueProtocol<Value>) -> ()
        ) -> any EZObserverTokenProtocol {
            _mainObservable.unknownAdd(
                wrapper: wrapper,
                action: action
            )
        }
        
        /// Type-erased variant of `addWithIsolation(...)`.
        ///
        /// ### Example
        /// ```swift
        /// $value.unknownAddWithIsolation(isolation: MainActor.shared) { _ in
        ///     // runs on the main actor when supported
        /// }
        /// ```
        @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
        @discardableResult
        public func unknownAddWithIsolation(
            isolation: (any Actor)? = #isolation,
            wrapper: (any EZObserverWrapperProtocol)? = nil,
            action: @escaping (any EZObserverValueProtocol<Value>) -> ()
        ) -> any EZObserverTokenProtocol {
            _mainObservable.unknownAddWithIsolation(
                isolation: isolation,
                wrapper: wrapper,
                action: action
            )
        }
        
        /// Type-erased variant of `addWithUnsafeIsolation(...)`.
        ///
        /// ### Example
        /// ```swift
        /// $value.unknownAddWithUnsafeIsolation { _ in
        ///     // handle event
        /// }
        /// ```
        @discardableResult
        public func unknownAddWithUnsafeIsolation(
            wrapper: (any EZObserverWrapperProtocol)? = nil,
            action: @escaping (any EZObserverValueProtocol<Value>) -> ()
        ) -> any EZObserverTokenProtocol {
            _mainObservable.unknownAddWithUnsafeIsolation(
                wrapper: wrapper,
                action: action
            )
        }
        
        /// Emits a notification using `type` without changing the stored value.
        ///
        /// This re-emits the current value as an event (effectively `old == new == current`).
        ///
        /// - Returns: `self` for fluent chaining.
        ///
        /// ### Example
        /// ```swift
        /// $value.signal(.common)
        /// $value.signal(.changeWrapper(MyWrapper()))
        /// ```
        @discardableResult
        public func signal(_ type: EZSetType) -> Self { _mainObservable.signal(type); return self }
        
        /// Removes an observer/subscription by its identifier.
        ///
        /// - Returns: `self` for fluent chaining.
        ///
        /// ### Example
        /// ```swift
        /// let token = $value.add { _ in }
        /// $value.remove(id: token.id)
        /// ```
        @discardableResult
        public func remove(id: UInt) -> Self { _mainObservable.remove(id: id); return self }
        
        fileprivate init(observable: EZObservable<Value>) {
            self._mainObservable = observable
        }
    }
}
