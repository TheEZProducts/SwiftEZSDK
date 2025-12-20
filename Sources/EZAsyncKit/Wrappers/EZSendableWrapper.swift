//
//  EZSendableWrapper.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

import EZHelpersKit
import EZMacrosKit

/// Small helpers to make values easier to pass across concurrency boundaries.
///
/// - `EZUnsafeSendableWrapper` is **@unchecked Sendable**: you are responsible for thread-safety.
/// - `@EZSendableWrapper` is a property macro that expands into `EZSendableWrapper<Value>` storage
///   backed by `EZRecursiveMutex` from `EZHelpersKit`, keeping classes and `static` globals
///   `Sendable`‑friendly.
/// - `EZSendableWrapper<Value>` is the underlying thread-safe storage type used by the macro.
///

/// Property macro that turns a stored property into a thread-safe, `Sendable`‑friendly field.
///
/// For a declaration like:
/// ```swift
/// final class Example: Sendable {
///     @EZSendableWrapper public internal(set) var text: String = "Hello"
/// }
/// ```
/// the macro roughly expands to:
/// ```swift
/// final class Example: Sendable {
///     public internal(set) var text: String {
///         _read { yield _text.wrappedValue }
///         _modify { yield &_text.wrappedValue }
///     }
///
///     public var $text: EZSendableWrapper<String>.ProjectedValue {
///         _read { yield _text.projectedValue }
///     }
///
///     internal let _text: EZSendableWrapper<String> = EZSendableWrapper(wrappedValue: "Hello")
/// }
/// ```
///
/// Access control is preserved in a `Sendable`‑friendly way:
/// - `text` keeps its original modifiers (e.g. `public internal(set)`),
/// - `$text` keeps the property’s main access level (e.g. `public`),
/// - `_text` uses the most restrictive setter access (e.g. `internal` for `public internal(set)`).
///
/// You can specify the value type either on the property:
/// ```swift
/// @EZSendableWrapper public internal(set) var string: String = "World"
/// ```
/// or by using the generic macro form:
/// ```swift
/// @EZSendableWrapper<String> public internal(set) var string = "World"
/// ```
///
/// In most cases you should use the macro, not `EZSendableWrapper<Value>` directly.
@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZSendableWrapper() = #externalMacro(module: "EZMacros", type: "EZConstantPropertyWrapperMacro")

/// Generic form of `@EZSendableWrapper` that spells the value type explicitly.
///
/// This is useful when type inference from the initializer is not desired or not possible.
///
/// ### Example
/// ```swift
/// @EZSendableWrapper<String> public internal(set) var string = "World"
/// ```
@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZSendableWrapper<T>() = #externalMacro(module: "EZMacros", type: "EZConstantPropertyWrapperMacro")

/// A minimal **@unchecked Sendable** box.
///
/// This does **not** provide any synchronization. Use only when the wrapped value is already
/// safe to share (e.g. immutable value types) or when you enforce your own locking.
///
/// ### Example
/// ```swift
/// let box = EZUnsafeSendableWrapper([1, 2, 3])
/// // You are responsible for ensuring safe access to `box.value`.
/// ```
public struct EZUnsafeSendableWrapper<Value>: @unchecked Sendable {
    public var value: Value
    
    public init(_ value: Value) {
        self.value = value
    }
}

/// Thread-safe backing storage used by the `@EZSendableWrapper` macro.
///
/// `EZSendableWrapper` wraps a value in an `EZRecursiveMutex` and exposes `get / set / update`
/// operations that are safe to call across threads.
///
/// `wrappedValue` provides convenient access, but for read–modify–write operations prefer `update(_:)`
/// to keep the whole mutation atomic. There are two overloads:
/// - a deprecated `(inout Value) -> R` variant, and
/// - the recommended overload that takes `EZAccess<Value>` and works well with noncopyable types.
///
/// ### Example (via the macro)
/// ```swift
/// final class Counter: Sendable {
///     @EZSendableWrapper var value: Int = 0
///
///     func inc() {
///         _value.update { access in
///             access.value += 1
///         }
///     }
/// }
/// ```
public final class EZSendableWrapper<Value>: EZConstantPropertyWrapperProtocol, Sendable {
    nonisolated(unsafe)
    private let _value: EZRecursiveMutex<Value>
    
    /// Projected value (`$property`) intended primarily for reading in user code.
    ///
    /// In typical usage you read through `$property` and perform mutations via the backing
    /// `_property` wrapper on the owning type.
    public var projectedValue: ProjectedValue { .init(_main: self) }
    
    /// Convenient access to the value.
    ///
    /// For compound mutations (read → modify → write), use `update(_:)` to avoid races:
    ///
    /// ```swift
    /// _value.update { access in
    ///     access.value += 1
    /// }
    /// ```
    public var wrappedValue: Value {
        set(value){ set(value) }
        get { update { $0.value } }
    }
    
    /// Returns the current value (synchronously, under the lock).
    @inline(__always)
    public func get() -> Value where Value: Copyable { _value.get() }
    
    /// Replaces the current value (synchronously, under the lock).
    @inline(__always)
    public func set(_ value: consuming Value) { _value.set(value) }
    
    /// Runs `closure` while holding the lock, allowing atomic read/modify/write.
    ///
    /// Deprecated: prefer the overload that takes `EZAccess<T>` instead, especially for noncopyable values.
    ///
    /// ### Example
    /// ```swift
    /// let old = _value.update { current in
    ///     defer { current += 1 }
    ///     return current
    /// }
    /// ```
    @available(*, deprecated, message: "Use update(_ closure: (borrowing EZAccess<T>) throws -> R) instead")
    @inline(__always)
    @discardableResult
    public func update<R>(_ closure: (inout Value) throws -> (R)) rethrows -> R where R: ~Copyable  {
        try update { try closure(&$0.value) }
    }
    
    /// Preferred `update` overload that exposes the underlying value via `EZAccess<T>`.
    ///
    /// This works well with noncopyable values and keeps the whole mutation atomic.
    ///
    /// ### Example
    /// ```swift
    /// let old = _value.update { access in
    ///     defer { access.value += 1 }
    ///     return access.value
    /// }
    /// ```
    @inline(__always)
    @discardableResult
    public func update<R>(_ closure: (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable {
        try _value.withLock(closure)
    }
    
    /// Creates the wrapper with an initial value.
    ///
    /// ### Example
    /// ```swift
    /// let storage = EZSendableWrapper(wrappedValue: 123)
    /// let current = storage.get()
    /// ```
    public init(wrappedValue: consuming Value) {
        _value = .init(wrappedValue)
    }
    
    /// Convenience initializer without an argument label.
    ///
    /// ### Example
    /// ```swift
    /// let storage = EZSendableWrapper(123)
    /// ```
    @inline(__always)
    public convenience init(_ value: consuming Value) {
        self.init(wrappedValue: value)
    }
}


extension EZSendableWrapper {
    /// Synchronous view of the projected value exposed as `$property`.
    ///
    /// This is what you get when you reference `$name`. The main intent is *reading* the
    /// current value (or computing a derived result under the same lock).
    ///
    /// Note: Mutating the stored value should be done through the backing `_name` wrapper.
    /// Calling `update` here passes the current `Value` into the closure; for value types this
    /// does not replace the stored value, while for reference types you may mutate the referenced
    /// object.
    public struct ProjectedValue: Sendable {
        let _main: EZSendableWrapper<Value>
        
        /// Synchronous access to the wrapped value.
        ///
        /// This is a read-only view of the current stored value.
        ///
        /// ### Example
        /// ```swift
        /// let current = $value.wrappedValue
        /// ```
        public var wrappedValue: Value {
            _read { yield _main.wrappedValue }
        }
        
        /// Computes a result under the same lock by passing the current `Value` into `closure`.
        ///
        /// This does not replace the stored value for value types (because `Value` is passed by value).
        /// It can still be useful for:
        /// - deriving a value consistently (read multiple fields under the same lock),
        /// - mutating reference types in-place.
        ///
        /// ### Example
        /// ```swift
        /// let length = $text.update { $0.count }
        /// ```
        @discardableResult
        public func update<R>(_ closure: @Sendable (Value) throws -> (R)) rethrows -> R where R: ~Copyable {
            try _main.update { try closure($0.value) }
        }
        
        /// Returns the current value.
        @discardableResult
        public func get() -> Value { _main.get() }
        
        init(_main: EZSendableWrapper<Value>) {
            self._main = _main
        }
    }
}
