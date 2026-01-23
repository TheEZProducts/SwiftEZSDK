//
//  EZRecursiveMutex.swift
//  EZSDK
//
//  Created by Александр Сенин on 09.12.2025.
//

import Foundation

/// A tiny mutex-protected box for `Value`, parameterized by a concrete lock type.
///
/// `EZLockingMutex` wraps a `Value` behind a lock that conforms to `EZLockProtocol`. It stores the
/// value in heap memory and exposes it through `EZBorrowedAccess<Value>` so that it works well with
/// noncopyable (`~Copyable`) types.
///
/// Typical usage is via higher-level helpers like `EZSendableWrapper` or `EZThreadSafety`, but this
/// type can also be used directly when you need fine-grained control over the lock.
///
/// ### Examples
/// ```swift
/// // High-level helpers: preferred in most cases
/// let mutex = EZMutex(0)
/// let recursiveMutex = EZRecursiveMutex(0)
///
/// let result = mutex.withLock { access in
///     access.value += 1
///     return access.value
/// }
/// ```
///
/// ```swift
/// // Using EZLockingMutex directly with a custom lock
/// struct MyLock: EZLockProtocol, ~Copyable {
///     // ... lock/unlock implementation ...
/// }
///
/// let customMutex = EZLockingMutex(MyLock(), 0)
/// let customResult = customMutex.withLock { access in
///     access.value += 1
///     return access.value
/// }
/// ```
public final class EZLockingMutex<Lock: EZLockProtocol, Value> where Value: ~Copyable, Lock: ~Copyable {
    private let _lock: Lock
    private let _ptr: UnsafeMutablePointer<Value>

    /// Runs `body` while holding the lock, exposing the stored value via `EZBorrowedAccess<Value>`.
    ///
    /// The lock is acquired before `body` is called and released afterwards, even if `body` throws.
    ///
    /// ### Example
    /// ```swift
    /// mutex.withLock { access in
    ///     access.value += 1
    /// }
    /// ```
    @inline(__always)
    public func withLock<R>(_ body: (borrowing EZBorrowedAccess<Value>) throws -> R) rethrows -> R where R: ~Copyable {
        _lock.lock(); defer { _lock.unlock() }
        return try body(EZBorrowedAccess(_ptr))
    }
    
    /// Returns a copy of the stored value.
    ///
    /// Available only when `Value` is `Copyable`.
    @inline(__always)
    public func get() -> Value where Value: Copyable {
        withLock { $0.value }
    }
    
    /// Replaces the stored value while holding the lock.
    @inline(__always)
    public func set(_ value: consuming Value) {
        _lock.lock(); defer { _lock.unlock() }
        _ptr.pointee = value
    }

    /// Creates a mutex-protected box with a concrete lock instance and initial value.
    ///
    /// Both the lock and the value are consumed and stored internally.
    public init(_ lock: consuming Lock, _ value: consuming Value) {
        _lock = lock
        _ptr = .allocate(capacity: 1)
        _ptr.initialize(to: value)
    }

    deinit {
        _ptr.deinitialize(count: 1)
        _ptr.deallocate()
    }
}

/// Marked as `@unchecked Sendable` when `Value` is `Sendable`.
///
/// It is the caller's responsibility to ensure that the chosen `Lock` correctly protects access.
extension EZLockingMutex: @unchecked Sendable where Value: Sendable {}
