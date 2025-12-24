//
//  File.swift
//
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

import EZHelpersKit
import EZMacrosKit

protocol EZThreadSafetyIsolatedValueProtocol<Value>: Sendable {
    associatedtype Value
    
    @discardableResult
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func update<R: Sendable>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) async rethrows -> R where R: ~Copyable
    
    @discardableResult
    func update<R>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable
}

/// Property macro that turns a stored property into a thread-safe, `Sendable`‑friendly field.
///
/// The macro exists to avoid `Sendable` pitfalls of traditional `@propertyWrapper` stored properties
/// in classes and `static` globals by generating a `let _name: EZThreadSafety<Value>` backing storage.
///
/// For a declaration like:
/// ```swift
/// final class Example: Sendable {
///     @EZThreadSafety public internal(set) var text: String = "Hello"
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
///     public var $text: EZThreadSafety<String>.Projection {
///         _read { yield _text.projectedValue }
///     }
///
///     internal let _text: EZThreadSafety<String> = EZThreadSafety(wrappedValue: "Hello")
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
/// @EZThreadSafety public internal(set) var string: String = "World"
/// ```
/// or by using the generic macro form:
/// ```swift
/// @EZThreadSafety<String> public internal(set) var string = "World"
/// ```
@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZThreadSafety() = #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_CMP")

///let
///-immutable - EZPropertyWrapper_LI_Macro
///-mutating - EZPropertyWrapper_LM_Macro
///
///var
///-immutable - EZPropertyWrapper_VI_Macro
///-mutating - EZPropertyWrapper_VM_Macro



/// Generic form of `@EZThreadSafety` that spells the value type explicitly.
///
/// ### Example
/// ```swift
/// @EZThreadSafety<String> public internal(set) var string = "World"
/// ```
@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZThreadSafety<T>() = #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_CMP")

/// Thread-safe access to a mutable value via `get / set / update`.
///
/// `EZThreadSafety` supports two usage modes and keeps them safe when mixed:
/// - **Sync mode** (non-`async` code): access is serialized via `EZRecursiveMutex`.
/// - **Async mode** (`async` code, on Swift Concurrency platforms): operations run under actor isolation
///   and still use `EZRecursiveMutex` under the hood to safely coordinate with sync access.
///
/// In practice this means:
/// - If you stay purely in async mode, access is serialized by the actor.
/// - If you stay purely in sync mode, access is serialized by the mutex.
/// - In mixed mode (sync + async), both paths share the same underlying storage and mutex, so you avoid races.
///
/// The `@EZThreadSafety` macro generates a `let _name: EZThreadSafety<Value>` backing storage.
/// Use `_name` for mutations (`update`/`set`) and `$name` primarily for reads or derived computations.
///
/// ### Example: pure async (actor provides isolation)
/// ```swift
/// struct Metrics: Sendable {
///     @EZThreadSafety var count: Int = 0
///
///     func inc() async {
///         await _count.update { access in
///             access.value += 1
///         }
///     }
///
///     func value() async -> Int {
///         await $count.get()
///     }
/// }
/// ```
///
/// ### Example: mixed mode (sync + async)
/// ```swift
/// final class Store: @unchecked Sendable {
///     @EZThreadSafety var items: [Int] = []
///
///     func addAsync(_ x: Int) async {
///         await _items.update { access in
///             access.value.append(x)
///         }
///     }
///
///     func countSync() -> Int {
///         $items.get().count
///     }
/// }
/// ```
public struct EZThreadSafety<Value: Sendable>: EZConstantPropertyWrapperProtocol, Sendable {
    private let value: (any EZThreadSafetyIsolatedValueProtocol<Value>)
    
    /// Access to the wrapped value.
    ///
    /// For atomic read/modify/write, prefer calling `update(_:)` on the backing `_property` wrapper.
    @available(*, noasync, message: "use let value = await $property.get() or await $property.set(value)")
    public var wrappedValue: Value {
        nonmutating set(value) {
            self.value.update { $0.value = value }
        }
        get {
            return value.update { $0.value }
        }
    }
    
    /// Projected value (`$property`) intended primarily for **reading** and **derived computations**.
    ///
    /// The key idea is:
    /// - Use `$name` to read the current value or compute a derived result under the same lock.
    /// - Use `_name` for mutations (`update` / `set`).
    ///
    /// ### Example: read (sync)
    /// ```swift
    /// final class Example: Sendable {
    ///     @EZThreadSafety var count: Int = 0
    ///
    ///     func readSync() -> Int {
    ///         $count.get()
    ///     }
    /// }
    /// ```
    ///
    /// ### Example: read (async)
    /// ```swift
    /// struct Metrics: Sendable {
    ///     @EZThreadSafety var count: Int = 0
    ///
    ///     func readAsync() async -> Int {
    ///         await $count.get()
    ///     }
    /// }
    /// ```
    ///
    /// ### Example: derived computation under the same lock
    /// ```swift
    /// let isPositive = $count.update { $0 > 0 }
    /// let digits = await $count.update { String($0).count }
    /// ```
    public var projectedValue: Projection {
        .init(main: self)
    }
    
    /// Atomically updates the stored value and returns a result (async).
    ///
    /// Deprecated: prefer the overload that takes `EZAccess<Value>` instead, especially for noncopyable values.
    ///
    /// ### Example
    /// ```swift
    /// let result = try await _value.update { current in
    ///     defer { current += 1 }
    ///     return current
    /// }
    /// ```
    @available(*, deprecated, message: "Use update(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> R) async rethrows -> R instead")
    @discardableResult
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func update<R: Sendable>(_ closure: @Sendable (inout Value) throws -> (R)) async rethrows -> R {
        try await value.update { try closure(&$0.value) }
    }
    
    /// Preferred async `update` overload that exposes the underlying value via `EZAccess<Value>`.
    ///
    /// Works well with noncopyable (`~Copyable`) values and keeps the whole mutation atomic.
    ///
    /// ### Example
    /// ```swift
    /// let result = try await _value.update { access in
    ///     defer { access.value += 1 }
    ///     return access.value
    /// }
    /// ```
    @discardableResult
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func update<R: Sendable>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) async rethrows -> R where R: ~Copyable {
        try await value.update(closure)
    }
    
    /// Atomically updates the stored value and returns a result (sync).
    ///
    /// Deprecated: prefer the overload that takes `EZAccess<Value>` instead, especially for noncopyable values.
    ///
    /// Safe to call from any thread.
    @available(*, deprecated, message: "Use update(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> R) instead")
    @_disfavoredOverload
    @discardableResult
    @available(*, noasync, message: "use await $property.update")
    public func update<R>(_ closure: @Sendable (inout Value) throws -> (R)) rethrows -> R {
        try value.update { try closure(&$0.value) }
    }
    
    /// Preferred sync `update` overload that exposes the underlying value via `EZAccess<Value>`.
    ///
    /// Safe to call from any thread and supports noncopyable (`~Copyable`) values.
    ///
    /// ### Example
    /// ```swift
    /// let result = _value.update { access in
    ///     defer { access.value += 1 }
    ///     return access.value
    /// }
    /// ```
    @discardableResult
    @available(*, noasync, message: "use await $property.update")
    public func update<R>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable {
        try value.update(closure)
    }
    
    /// Sets the value (async).
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func set(_ value: Value) async {
        await update { $0.value = value }
    }
    
    /// Sets the value (sync).
    @available(*, noasync, message: "use await $property.set")
    public func set(_ value: Value) {
        update { $0.value = value }
    }
    
    /// Gets the current value (async).
    @discardableResult
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func get() async -> Value {
        await update { $0.value }
    }
    
    /// Gets the current value (sync).
    @discardableResult
    @available(*, noasync, message: "use await $property.get")
    public func get() -> Value {
        update { $0.value }
    }
    
    /// Creates a thread-safe wrapper around `wrappedValue`.
    public init(wrappedValue: Value){
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            self.value = ActorIsolatedValue(value: wrappedValue)
        } else {
            self.value = EZSendableWrapper(wrappedValue: wrappedValue)
        }
    }
    
    @inline(__always)
    public init(_ value: Value) {
        self.init(wrappedValue: value)
    }
}

/// Property macro that exposes a read-only *projection-backed* value with constant backing storage.
///
/// This is the immutable companion to `@EZThreadSafety`: it uses the same constant-storage macro
/// pattern, but generates a getter-only property.
///
/// The public-facing property is typically declared as the *plain value type* (e.g. `Int`).
/// The macro then generates a constant backing storage (e.g. `let _counterView: EZThreadSafetyProjection<Int>`)
/// which you usually initialize in `init`.
///
/// This is useful when you want to keep a projection view as a stored member (e.g. in a `Sendable`
/// class) without introducing a mutable stored wrapper variable.
///
/// ### Example
/// ```swift
/// final class Source: Sendable {
///     @EZThreadSafety var counter: Int = 0
/// }
///
/// final class Example: Sendable {
///     @EZThreadSafetyProjection var counterView: Int
///
///     init(counterView: EZThreadSafetyProjection<Int>) {
///         // Initialize the generated backing storage.
///         _counterView = counterView
///     }
///
///     func read() -> Int { counterView }
/// }
///
/// let source = Source()
/// let example = Example(counterView: source.$counter)
/// _ = example.read()
/// ```
@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZThreadSafetyProjection() = #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_CIP")

/// Generic form of `@EZThreadSafetyProjection` that spells the value type explicitly.
///
/// ### Example
/// ```swift
/// final class Source: Sendable {
///     @EZThreadSafety var counter: Int = 0
/// }
///
/// final class Example: Sendable {
///     @EZThreadSafetyProjection<Int> var counterView: Int
///
///     init(counterView: EZThreadSafetyProjection<Int>) {
///         _counterView = counterView
///     }
/// }
///
/// let source = Source()
/// let example = Example(counterView: source.$counter)
/// _ = example
/// ```
@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro EZThreadSafetyProjection<T>() = #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_CIP")

/// Convenience alias for `EZThreadSafety<Value>.Projection`.
public typealias EZThreadSafetyProjection<Value: Sendable> = EZThreadSafety<Value>.Projection

extension EZThreadSafety {
    /// Synchronous view of the projected value exposed as `$property`.
    ///
    /// The main intent is reading the current value (or computing a derived result) under the same lock.
    /// Mutating the stored value should be done through the backing `_property` wrapper.
    public struct Projection: EZConstantImmutablePropertyWrapperProtocol, Sendable {
        let _main: EZThreadSafety<Value>
        
        /// Synchronous read-only access to the current stored value.
        ///
        /// ### Example
        /// ```swift
        /// let current = $value.wrappedValue
        /// ```
        public var wrappedValue: Value {
            _read { yield _main.wrappedValue }
        }
        
        public var projectedValue: Self { self }
        
        /// Computes a result under the same lock by passing the current `Value` into `closure` (async).
        ///
        /// Note: for value types this does not replace the stored value (because `Value` is passed by value).
        /// For mutations use `_property.update` on the backing wrapper.
        ///
        /// ### Example
        /// ```swift
        /// let count = await $text.update { $0.count }
        /// ```
        @discardableResult
        @_disfavoredOverload
        @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
        public func update<R: Sendable>(_ closure: @Sendable (Value) throws -> (R)) async rethrows -> R where R: ~Copyable {
            try await _main.update { try closure($0.value) }
        }
                
        /// Computes a result under the same lock by passing the current `Value` into `closure` (sync).
        ///
        /// Note: for value types this does not replace the stored value (because `Value` is passed by value).
        /// For mutations use `_property.update` on the backing wrapper.
        ///
        /// ### Example
        /// ```swift
        /// let count = $text.update { $0.count }
        /// ```
        @discardableResult
        @available(*, noasync, message: "use await $property.update")
        public func update<R>(_ closure: @Sendable (Value) throws -> (R)) rethrows -> R where R: ~Copyable {
            try _main.update { try closure($0.value) }
        }
        
        /// Returns the current value.
        @discardableResult
        @_disfavoredOverload
        @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
        public func get() async -> Value { await _main.get() }
        
        /// Returns the current value.
        @discardableResult
        @available(*, noasync, message: "use await $property.get")
        public func get() -> Value { _main.get() }
        
        public init(main: EZThreadSafety<Value>) {
            self._main = main
        }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
actor ActorIsolatedValue<Value: Sendable>: EZThreadSafetyIsolatedValueProtocol {
    let _value: EZRecursiveMutex<Value>
    
    @inline(__always)
    @discardableResult
    nonisolated
    func update<R: Sendable>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) async rethrows -> R where R: ~Copyable  {
        try await isolatedUpdate(closure)
    }
    
    @inline(__always)
    @discardableResult
    private func isolatedUpdate<R>(_ closure: (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable  {
        try _value.withLock(closure)
    }
    
    
    @inline(__always)
    @discardableResult
    nonisolated
    func update<R>(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable {
        try nonisolatedUpdate(closure)
    }
    
    @inline(__always)
    @discardableResult
    nonisolated
    private func nonisolatedUpdate<R>(_ closure: (borrowing EZAccess<Value>) throws -> (R)) rethrows -> R where R: ~Copyable {
        try _value.withLock(closure)
    }
    
    init(value: consuming Value) {
        self._value = .init(value)
    }
}

extension EZSendableWrapper: EZThreadSafetyIsolatedValueProtocol { }
 
