//
//  AsyncScream+.swift
//  EZSDK
//
//  Created by Александр Сенин on 03.12.2025.
//

import Foundation

#if canImport(EZAssociatedKit)
import EZAssociatedKit
#endif

extension EZDeinitAnchor {
    convenience init<Element>(continuation: AsyncStream<Element>.Continuation) {
        self.init { continuation.finish() }
    }
}


extension AsyncStream.Continuation {
    /// Finishes the stream after `duration`.
    ///
    /// This starts a `Task` that sleeps for the given duration and then calls `finish()`.
    ///
    /// ### Example
    /// ```swift
    /// continuation.ezSetTimeout(duration: .seconds(5))
    /// ```
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func ezSetTimeout(duration: Duration) {
        Task {
            try await Task.sleep(for: duration)
            finish()
        }
    }
    
    /// Creates a `EZDeinitAnchor` that calls `finish()` when the anchor is deallocated.
    ///
    /// Useful to tie the stream's lifetime to some owning object.
    ///
    /// ### Example
    /// ```swift
    /// let anchor = continuation.ezMakeAnchor()
    /// // When `anchor` deallocates, the stream is finished.
    /// ```
    public func ezMakeAnchor() -> EZDeinitAnchor { .init(continuation: self) }
    
    /// Creates an anchor (via `ezMakeAnchor()`) and passes it into `action`.
    ///
    /// Returns `self` for convenient chaining.
    ///
    /// ### Example
    /// ```swift
    /// continuation.ezMakeAnchor { anchor in
    ///     _ = anchor // store / attach
    /// }
    /// ```
    @discardableResult
    public func ezMakeAnchor(_ action: (EZDeinitAnchor) -> ()) -> Self {
        action(ezMakeAnchor())
        return self
    }
    
#if canImport(EZAssociatedKit) && canImport(ObjectiveC)
    /// Attaches a finishing anchor to an Objective-C object via associated objects.
    ///
    /// The stream will be finished when `object` is released.
    ///
    /// ### Example
    /// ```swift
    /// final class Owner: NSObject {}
    /// let owner = Owner()
    ///
    /// continuation
    ///     .ezSnapToObject(owner)
    /// // When `owner` deallocates, the stream is finished.
    /// ```
    @discardableResult
    public func ezSnapToObject(_ object: AnyObject) -> Self {
        ezMakeAnchor { $0.ezSnapToObject(object) }
    }
#endif
}
