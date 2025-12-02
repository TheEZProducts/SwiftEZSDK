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
    @available(macOS 13.0, iOS 16.0, watchOS 9.0, tvOS 16.0, *)
    public func ezSetTimeout(duration: Duration) {
        Task {
            try await Task.sleep(for: duration)
            finish()
        }
    }
    
    public func ezMakeAnchor() -> EZDeinitAnchor { .init(continuation: self) }
    
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
