//
//  Actor + Task.swift
//  EZSDK
//
//  Created by Александр Сенин on 02.12.2025.
//

import Foundation

extension Actor {
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
    nonisolated
    public var isIsolated: Bool {
        let isIsolated = EZSendableWrapper(wrappedValue: false)
        ezTaskImmediate { _ in isIsolated.wrappedValue = true }
        return isIsolated.wrappedValue
    }
    
    public func ezWithIsolation<T>(_ body: @Sendable (isolated Self) async throws -> T) async rethrows -> T {
        try await body(self)
    }
    
    @discardableResult
    nonisolated
    public func ezTask<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
        let body = EZUnsafeSendableWrapper(operation)
        return ezUnsafeRun { $0.makeTask(name: name, priority: priority, operation: body.value) }
    }
    
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
    @discardableResult
    nonisolated
    public func ezTaskImmediate<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
        let body = EZUnsafeSendableWrapper(operation)
        return ezUnsafeRun { $0.makeTaskImmediate(name: name, priority: priority, operation: body.value) }
    }
    
    @discardableResult
    nonisolated
    public func ezTaskDetached<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @Sendable @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
        let body = EZUnsafeSendableWrapper(operation)
        return ezUnsafeRun { $0.makeTaskDetached(name: name, priority: priority, operation: body.value) }
    }
    
    nonisolated
    public func ezUnsafeRun<R>(_ body: @escaping (isolated Self) throws -> (R)) throws -> R {
        let unsafeAction = unsafeBitCast(body, to: ((Self) throws -> (R)).self)
        return try unsafeAction(self)
    }
    
    nonisolated
    public func ezUnsafeRun<R>(_ body: @escaping (isolated Self) -> (R)) -> R {
        let unsafeAction = unsafeBitCast(body, to: ((Self) -> (R)).self)
        return unsafeAction(self)
    }
        
    private func makeTask<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
        .init(name: name, priority: priority) { try await operation(self) }
    }
    
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
    private func makeTaskImmediate<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
        .immediate(name: name, priority: priority) { try await operation(self) }
    }
    
    private func makeTaskDetached<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @Sendable @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error> {
        .detached(name: name, priority: priority) { try await self.ezWithIsolation {
            try await operation($0)
        }}
    }
}
