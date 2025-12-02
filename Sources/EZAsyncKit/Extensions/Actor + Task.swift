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
    
    public func ezWithIsolation<T>(_ body: @Sendable (isolated Self) throws -> T) rethrows -> T {
        try body(self)
    }
    
    @discardableResult
    nonisolated
    public func ezTask<R>(_ body: @escaping (isolated Self) throws -> R) -> Task<R, Error> {
        let body = EZUnsafeSendableWrapper(body)
        return ezUnsafeRun { $0.makeTask(body.value) }
    }
    
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
    @discardableResult
    nonisolated
    public func ezTaskImmediate<R>(_ body: @escaping (isolated Self) throws -> R) -> Task<R, Error> {
        let body = EZUnsafeSendableWrapper(body)
        return ezUnsafeRun { $0.makeTaskImmediate(body.value) }
    }
    
    @discardableResult
    nonisolated
    public func ezTaskDetached<R>(_ body: @Sendable @escaping (isolated Self) throws -> R) -> Task<R, Error> {
        let body = EZUnsafeSendableWrapper(body)
        return ezUnsafeRun { $0.makeTaskDetached(body.value) }
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
        
    private func makeTask<R>(_ body: @escaping (isolated Self) throws -> R) -> Task<R, Error> {
        .init { try body(self) }
    }
    
    @available(macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, *)
    private func makeTaskImmediate<R>(_ body: @escaping (isolated Self) throws -> R) -> Task<R, Error> {
        .immediate { try body(self) }
    }
    
    private func makeTaskDetached<R>(_ body: @Sendable @escaping (isolated Self) throws -> R) -> Task<R, Error> {
        .detached { try await self.ezWithIsolation {
            try body($0)
        }}
    }
}
