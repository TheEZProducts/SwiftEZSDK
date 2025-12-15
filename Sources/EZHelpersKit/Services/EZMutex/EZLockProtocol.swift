//
//  EZLockProtocol.swift
//  EZSDK
//
//  Created by Александр Сенин on 11.12.2025.
//

import Foundation

/// Minimal locking interface used by `EZLockingMutex`.
///
/// Any concrete lock type that wants to integrate with the helpers in this module can conform
/// to `EZLockProtocol` by implementing `lock()` and `unlock()`.
///
/// Typical conformers are recursive or non-recursive mutex types (e.g. `NSLock`, `NSRecursiveLock`,
/// `NSConditionLock`), but custom locks are also supported.
///
/// The protocol is `~Copyable` so that lock values are not implicitly copied.
///
/// ### Example
/// ```swift
/// struct MyLock: EZLockProtocol, ~Copyable {
///     func lock()   { /* acquire */ }
///     func unlock() { /* release */ }
/// }
/// ```
public protocol EZLockProtocol: ~Copyable {
    func lock()
    func unlock()
}

extension NSRecursiveLock: EZLockProtocol {}
extension NSConditionLock: EZLockProtocol {}
extension NSLock: EZLockProtocol {}
