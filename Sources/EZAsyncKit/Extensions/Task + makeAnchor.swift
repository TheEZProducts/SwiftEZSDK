//
//  Task+.swift
//  EZSDK
//
//  Created by Александр Сенин on 05.03.2025.
//

import Foundation

#if canImport(EZAssociatedKit)
import EZAssociatedKit
#endif

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension EZDeinitAnchor {
    public convenience init<Success, Failure>(task: Task<Success, Failure>) {
        self.init { task.cancel() }
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Task {
    public func ezMakeAnchor() -> EZDeinitAnchor { .init(task: self) }
    
    @discardableResult
    public func ezMakeAnchor(_ action: (EZDeinitAnchor) -> ()) -> Self {
        action(ezMakeAnchor())
        return self
    }
    
#if canImport(EZAssociatedKit) && canImport(ObjectiveC)
    @discardableResult
    public func ezSnapToObject(_ object: AnyObject) -> Self {
        ezMakeAnchor{
            EZAssociated(object).set($0, .random, .OBJC_ASSOCIATION_RETAIN)
        }
    }
#endif
}

extension Task {
    public func ezSnapToCurrentTask(isolation: isolated (any Actor)? = #isolation) async throws -> Success {
        try await withTaskCancellationHandler(
            operation: { try await result.get() },
            onCancel: { cancel() },
            isolation: isolation
        )
    }
}
