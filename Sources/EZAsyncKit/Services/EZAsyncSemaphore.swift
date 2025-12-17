//
//  EZAsyncSemaphore.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.12.2025.
//

import EZHelpersKit

/// A small async semaphore for coordinating concurrent tasks.
///
/// Similar to a classic counting semaphore:
/// - `wait()` decrements the permit count; if it becomes negative, the caller suspends until a permit is available.
/// - `signal()` increments the permit count and resumes one waiting task (if any).
///
/// Cancellation: `wait()` checks for `Task` cancellation and uses a stoppable continuation, so if the task
/// is cancelled while suspended, it throws `CancellationError` and the internal permit counter is restored.
///
/// ### Example
/// ```swift
/// let semaphore = EZAsyncSemaphore(value: 2)
///
/// await withTaskGroup(of: Void.self) { group in
///     for i in 0..<5 {
///         group.addTask {
///             try await semaphore.wait()
///             defer { Task { await semaphore.signal() } }
///             // critical section
///         }
///     }
/// }
/// ```
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZAsyncSemaphore {
    private var permits: Int
    private var tasks = EZHeadQueue<EZSafeContinuation<Void>>()
    
    /// Releases a permit and resumes one suspended waiter if available.
    ///
    /// If there are no waiting tasks, the permit is stored for the next `wait()` call.
    public func signal() {
        permits += 1
        tasks.dequeueThroughFirst { $0.result == nil }?.resume()
    }
    
    /// Acquires a permit, suspending if necessary.
    ///
    /// If a permit is available, returns immediately. Otherwise, suspends until another task calls `signal()`.
    /// Throws `CancellationError` if the calling task is cancelled while waiting.
    public func wait() async throws {
        try Task.checkCancellation()
        permits -= 1
        guard permits < 0 else { return }
        do {
            try await ezWithCheckedStoppableContinuation { tasks.enqueue($0) }
        } catch {
            permits += 1
            throw error
        }
    }
    
    /// Creates a semaphore with the given initial number of permits.
    ///
    /// Negative values are clamped to zero.
    public init(value: Int = 1){
        permits = max(0, value)
    }
}
