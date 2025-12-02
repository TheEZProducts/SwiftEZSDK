//
//  EZActorIsolator.swift
//  EZSDK
//
//  Created by Александр Сенин on 15.03.2025.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class EZActorIsolator<Value>: Sendable {
    private let isolation: any Actor
    
    nonisolated(unsafe)
    private var value: Value
    
    public init(isolation: any Actor = #isolation, value: Value) {
        self.isolation = isolation
        self.value = value
    }
    
    @discardableResult
    public func update<R: Sendable>(_ action: @Sendable (inout Value) throws -> (R)) async rethrows -> R {
        try await update(isolation: isolation, action)
    }
    
    public func update<R: Sendable>(
        _ action: @Sendable @escaping (inout Value) throws -> (R),
        result: @Sendable @escaping (Result<R, Error>) -> () = {_ in}
    ) {
        Task {
            do{
                result(.success(try await update(isolation: isolation, action)))
            }catch {
                result(.failure(error))
            }
        }
    }
    
    @discardableResult
    public func unsafeUpdate<R: Sendable>(_ action: @Sendable (inout Value) throws -> (R)) rethrows -> R {
        try update(isolation: nil, action)
    }
    
    @discardableResult
    private func update<R: Sendable>(
        isolation: isolated (any Actor)?,
        _ action: (inout Value) throws -> (R)
    ) rethrows -> R {
        try action(&value)
    }
}
