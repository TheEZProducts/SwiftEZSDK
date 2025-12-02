//
//  EZContinuation.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public enum EZContinuationError: String, LocalizedError, Sendable {
    case wasDeinit = "Was deallocated"
    
    public var errorDescription: String? { "EZContinuationError: \(rawValue)" }
}

public protocol EZContinuationProtocol<T, E>: Sendable {
    associatedtype T
    associatedtype E: Error
    
    func resume(throwing error: E)
    func resume(returning value: sending T)
}

extension EZContinuationProtocol{
    public func resume<Er>(with result: sending Result<T, Er>) where E == any Error, Er : Error {
        switch result {
        case .success(let value):
            resume(returning: value)
        case .failure(let error):
            resume(throwing: error)
        }
    }
    
    public func resume(with result: sending Result<T, E>) {
        switch result {
        case .success(let value):
            resume(returning: value)
        case .failure(let error):
            resume(throwing: error)
        }
    }
    
    public func resume() where T == () {
        resume(returning: ())
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension CheckedContinuation: EZContinuationProtocol {}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
extension UnsafeContinuation: EZContinuationProtocol {}


@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class EZActionContinuation<T: Sendable>: Sendable, EZContinuationProtocol {
    let action: EZThreadSafety<(@Sendable (Result<T, Error>) async -> Void)?>
    
    public init(action: @escaping @Sendable (Result<T, Error>) async -> Void) {
        self.action = .init(wrappedValue: action)
    }
    
    public func resume(with result: Result<T, Error>) {
        action.update{action in
            Task{[action] in
                await action?(result)
            }
            action = nil
        }
    }
    
    public func resume(throwing error: Error) {
        resume(with: .failure(error))
    }
    
    public func resume(returning value: sending T) {
        resume(with: .success(value))
    }
    
    deinit{
        resume(with: .failure(EZContinuationError.wasDeinit))
    }
}

extension EZSafeContinuation {
    struct Storage: Sendable {
        var continuation: CheckedContinuation<T, Error>?
        var result: Result<T, Error>?
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class EZSafeContinuation<T: Sendable>: Sendable, EZContinuationProtocol {
    private let storage: EZThreadSafety<Storage>
    public var result: Result<T, Error>? { storage.wrappedValue.result }
    
    public init(continuation: CheckedContinuation<T, Error>? = nil) {
        storage = .init(wrappedValue: .init(continuation: continuation))
    }
    
    public func set(continuation: CheckedContinuation<T, Error>? = nil) {
        storage.update {
            if let value = $0.result {
                continuation?.resume(with: value)
            }else{
                $0.continuation = continuation
            }
        }
    }
    
    public func resume(throwing error: Error) {
        resume(with: .failure(error))
    }
    
    public func resume(returning value: sending T) {
        resume(with: .success(value))
    }
    
    public func resume(with result: sending Result<T, Error>) {
        storage.update {[result] in
            guard $0.result == nil else { return }
            $0.result = result
            $0.continuation?.resume(with: result)
            $0.continuation = nil
        }
    }
     
    deinit { resume(with: .failure(EZContinuationError.wasDeinit)) }
}
