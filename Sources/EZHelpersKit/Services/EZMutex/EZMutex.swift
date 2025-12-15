//
//  EZMutex.swift
//  EZSDK
//
//  Created by Александр Сенин on 09.12.2025.
//

import Foundation

/// A convenience alias for `EZLockingMutex` using `NSLock` as the underlying lock.
///
/// `EZMutex` gives you a simple mutex-protected box for a single `Value`, backed by `NSLock`
/// and compatible with noncopyable (`~Copyable`) values via `EZAccess<Value>`.
///
/// ### Example
/// ```swift
/// let mutex = EZMutex(0)
/// let result = mutex.withLock { access in
///     access.value += 1
///     return access.value
/// }
/// ```
public typealias EZMutex<Value> = EZLockingMutex<NSLock, Value> where Value: ~Copyable

extension EZMutex where Lock == NSLock, Value: ~Copyable {
    /// Creates a mutex-protected box with a fresh `NSLock` and initial value.
    ///
    /// This is the primary way to construct `EZMutex` at call sites.
    public convenience init(_ value: consuming Value) {
        self.init(.init(), consume value)
    }
}
