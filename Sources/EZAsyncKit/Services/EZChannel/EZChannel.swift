//
//  EZChannel.swift
//  EZSDK
//
//  Created by Александр Сенин on 05.05.2025.
//

import Foundation

public enum EZChannelError: String, LocalizedError, Sendable {
    case closed = "Channel is closed"
    
    public var errorDescription: String? {
        "EZChannel.ChannelError: \(rawValue)"
    }
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZChannel<T: Sendable> {
    public private(set) var isClosed: Bool = false
    
    private var continuations = (
        setContinuations: [EZSafeContinuation<EZSafeContinuation<T>>](),
        getContinuations: [EZSafeContinuation<T>]()
    )
    
    public func get() async throws -> T {
        try checkIsClosed()
        return try await ezWithCheckedStoppableContinuation { getContinuation in
            if let continuation = continuations.setContinuations.ezSafeRemoveFirst() {
                continuation.resume(returning: getContinuation)
            }else{
                continuations.getContinuations.append(getContinuation)
            }
        }
    }
    
    public func set(_ value: T) async throws {
        try checkIsClosed()
        try await ezWithCheckedStoppableContinuation { continuation in
            if let getContinuation = continuations.getContinuations.ezSafeRemoveFirst() {
                continuation.resume(returning: getContinuation)
            } else {
                continuations.setContinuations.append(continuation)
            }
        }.resume(returning: value)
    }
    
    public func close() {
        isClosed = true
        continuations.getContinuations.forEach { $0.resume(throwing: EZChannelError.closed) }
        continuations.setContinuations.forEach { $0.resume(throwing: EZChannelError.closed) }
    }
    
    public func checkIsClosed() throws {
        guard !isClosed else { throw EZChannelError.closed }
    }
    
    public init(){}
}

