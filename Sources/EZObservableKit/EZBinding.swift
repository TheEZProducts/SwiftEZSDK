//
//  File.swift
//
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

/// A minimal `@propertyWrapper` that forwards reads and writes to provided closures.
///
/// `EZBinding` models the core behavior of SwiftUI's `Binding`: it stores a `get` closure and a
/// `set` closure and exposes them via `wrappedValue`.
///
/// Lightweight fallback for SwiftUI's `Binding` on older OS versions.
///
/// On modern platforms you should prefer SwiftUI's `Binding`. `EZBinding` exists primarily for
/// deployment targets below iOS 13 / macOS 10.15 (and similar), where the standard `Binding`
/// type is not available.
///
/// - Important: Prefer SwiftUI's `Binding` when it is available.
///
/// ### Example
/// ```swift
/// var storage = 0
/// let binding = EZBinding(
///     get: { storage },
///     set: { storage = $0 }
/// )
///
/// binding.wrappedValue += 1
/// print(storage) // 1
/// ```
@propertyWrapper
public struct EZBinding<Value>: Sendable {
    private let get: @Sendable () -> Value
    private let set: @Sendable (Value) -> Void
    
    /// Reads and writes the bound value using the stored closures.
    public var wrappedValue: Value{
        nonmutating set(value) { set(value) }
        get { get() }
    }
    /// Re-assigns the current value to itself.
    ///
    /// This is a small convenience to force the `set` closure to run with the current value.
    mutating public func update(){ wrappedValue = wrappedValue }
    
    /// Creates a binding from explicit `get` and `set` closures.
    public init(get: @Sendable @escaping () -> Value, set: @Sendable @escaping (Value) -> Void){
        self.get = get
        self.set = set
    }
}
