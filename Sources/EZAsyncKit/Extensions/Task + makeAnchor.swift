//
//  Task+.swift
//  EZSDK
//
//  Created by Александр Сенин on 05.03.2025.
//

import Foundation

import EZHelpersKit

#if canImport(EZAssociatedKit)
import EZAssociatedKit
#endif


@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension EZDeinitAnchor {
    /// Creates an anchor that cancels `task` on deallocation.
    ///
    /// ### Example
    /// ```swift
    /// let task = Task { /* work */ }
    /// let anchor = EZDeinitAnchor(task: task)
    /// // When `anchor` deallocates, `task` is cancelled.
    /// ```
    public convenience init<Success, Failure>(task: Task<Success, Failure>) {
        self.init { task.cancel() }
    }
}

/// Convenience helpers for attaching `Task` cancellation to object lifetimes.
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Task {
    /// Creates a `EZDeinitAnchor` that cancels this task when the anchor is deallocated.
    ///
    /// ### Example
    /// ```swift
    /// let task = Task { /* do work */ }
    /// let anchor = task.ezMakeAnchor()
    /// ```
    public func ezMakeAnchor() -> EZDeinitAnchor { .init(task: self) }
    
    /// Creates an anchor (via `ezMakeAnchor()`) and passes it into `action`.
    ///
    /// Useful for immediately snapping the anchor somewhere, while returning `self` for chaining.
    ///
    /// ### Example
    /// ```swift
    /// let task = Task { /* work */ }
    /// task.ezMakeAnchor { anchor in
    ///     _ = anchor // store / attach
    /// }
    /// ```
    @discardableResult
    public func ezMakeAnchor(_ action: (EZDeinitAnchor) -> ()) -> Self {
        action(ezMakeAnchor())
        return self
    }
    
#if canImport(EZAssociatedKit) && canImport(ObjectiveC)
    /// Attaches a cancellation anchor to an Objective-C object via associated objects.
    ///
    /// The task will be cancelled when `object` is released.
    ///
    /// ### Example
    /// ```swift
    /// final class Owner: NSObject {}
    /// let owner = Owner()
    ///
    /// Task { /* work */ }
    ///     .ezSnapToObject(owner)
    /// // When `owner` deallocates, the task is cancelled.
    /// ```
    @discardableResult
    public func ezSnapToObject(_ object: AnyObject) -> Self {
        ezMakeAnchor { $0.ezSnapToObject(object) }
    }
#endif
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Task {
    /// Awaits this task's result, and cancels this task if the *current* task is cancelled.
    ///
    /// This is a convenience wrapper around `withTaskCancellationHandler`.
    ///
    /// ### Example
    /// ```swift
    /// let background = Task { try await doWork() }
    /// let value = try await background.ezSnapToCurrentTask()
    /// ```
    public func ezSnapToCurrentTask(isolation: isolated (any Actor)? = #isolation) async throws -> Success {
        try await withTaskCancellationHandler(
            operation: { try await result.get() },
            onCancel: { cancel() },
            isolation: isolation
        )
    }
}
