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
public final class EZTaskAnchor: Sendable{
    private let cancelAction: @Sendable () -> ()
    
    public init<Success, Failure>(task: Task<Success, Failure>) {
        self.cancelAction = { task.cancel() }
    }
    
    public func cancel(){
        cancelAction()
    }
    
    deinit{
        cancel()
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension Task {
    public func ezMakeAnchor() -> EZTaskAnchor { .init(task: self) }
    
    @discardableResult
    public func ezMakeAnchor(_ action: (EZTaskAnchor) -> ()) -> Self {
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
