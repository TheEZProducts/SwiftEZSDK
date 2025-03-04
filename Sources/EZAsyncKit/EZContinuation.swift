//
//  EZContinuation.swift
//  EZSDK
//
//  Created by Александр Сенин on 04.03.2025.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public enum EZContinuationError: Error{
    case wasDeinit
}

public protocol EZContinuationProtocol<T, E>: Sendable{
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

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class EZSafeContinuation<T: Sendable>: Sendable, EZContinuationProtocol {
    private let _continuation: EZThreadSafety<CheckedContinuation<T, Error>?>
    private let _result = EZThreadSafety<Result<T, Error>?>(wrappedValue: nil)
    
    public var result: Result<T, Error>? { _result.wrappedValue }
    
    public init(continuation: CheckedContinuation<T, Error>? = nil) {
        self._continuation = .init(wrappedValue: continuation)
    }
    
    public func set(continuation: CheckedContinuation<T, Error>? = nil) {
        _result.update{
            if let value = $0 {
                continuation?.resume(with: value)
            }else{
                self._continuation.set(continuation)
            }
        }
    }
    
    public func resume(throwing error: Error) {
        guard result == nil else { return }
        _continuation.update{
            _result.set(.failure(error))
            $0?.resume(throwing: error)
            $0 = nil
        }
    }
    
    public func resume(returning value: sending T) {
        guard result == nil else { return }
        _continuation.update{[value] in
            _result.set(.success(value))
            $0?.resume(returning: value)
            $0 = nil
        }
    }
    
    deinit {
        resume(with: .failure(EZContinuationError.wasDeinit))
    }
}
