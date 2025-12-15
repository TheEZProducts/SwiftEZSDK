//
//  EZRecursiveMutex.swift
//  EZSDK
//
//  Created by Александр Сенин on 11.12.2025.
//

import Foundation

/// A convenience alias for `EZLockingMutex` using `NSRecursiveLock` as the underlying lock.
///
/// `EZRecursiveMutex` behaves like `EZMutex`, but allows the same thread to acquire the lock
/// multiple times (recursive locking).
///
/// This is useful when your code paths may re-enter protected sections on the same thread while
/// still needing mutual exclusion against other threads.
///
/// ### Example
/// ```swift
/// let mutex = EZRecursiveMutex(0)
///
/// func incrementRecursively(_ depth: Int) {
///     guard depth > 0 else { return }
///     mutex.withLock { access in
///         access.value += 1
///         incrementRecursively(depth - 1) // safe: same thread can re-lock
///     }
/// }
/// ```
///
/// Note: recursive locks can hide some design issues; prefer a plain `EZMutex` when re-entrancy
/// is not required.
public typealias EZRecursiveMutex<Value> = EZLockingMutex<NSRecursiveLock, Value> where Value: ~Copyable

extension EZRecursiveMutex where Lock == NSRecursiveLock, Value: ~Copyable {
    /// Creates a recursive mutex-protected box with a fresh `NSRecursiveLock` and initial value.
    public convenience init(_ value: consuming Value) {
        self.init(.init(), value)
    }
}
