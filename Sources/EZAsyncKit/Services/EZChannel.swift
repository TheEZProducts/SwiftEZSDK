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
            if let continuation = continuations.setContinuations.tryRemoveFirst(){
                continuation.resume(returning: getContinuation)
            }else{
                continuations.getContinuations.append(getContinuation)
            }
        }
    }
    
    public func set(_ value: T) async throws {
        try checkIsClosed()
        try await ezWithCheckedStoppableContinuation { continuation in
            if let getContinuation = continuations.getContinuations.tryRemoveFirst(){
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
    
    private func checkIsClosed() throws {
        guard !isClosed else { throw EZChannelError.closed }
    }
    
    public init(){}
}


@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZBufferedChannel<T: Sendable> {
    public private(set) var isClosed: Bool = false
    
    private var bufferSize: Int { buffer.capacity }
    private var buffer: [T] = []
    
    public init(bufferSize: Int) {
        buffer = .init(unsafeUninitializedCapacity: bufferSize, initializingWith: {_,_ in})
    }
    
    private var continuations = (
        setContinuations: [(value: T, continuation: EZSafeContinuation<Void>)](),
        getContinuations: [EZSafeContinuation<T>]()
    )
    
    public func get() async throws -> T {
        try checkIsClosed()
        if let value = buffer.tryRemoveFirst() {
            setNextValue()
            return value
        } else {
            return try await ezWithCheckedStoppableContinuation { getContinuation in
                continuations.getContinuations.append(getContinuation)
            }
        }
    }
    
    public func set(_ value: T) async throws {
        try checkIsClosed()
        if let getContinuation = continuations.getContinuations.tryRemoveFirst() {
            getContinuation.resume(returning: value)
        } else if buffer.count < bufferSize {
            buffer.append(value)
        } else {
            try await ezWithCheckedStoppableContinuation { continuation in
                continuations.setContinuations.append((value, continuation))
            }
        }
    }
    
    public func close() {
        isClosed = true
        continuations.getContinuations.forEach { $0.resume(throwing: EZChannelError.closed) }
        continuations.setContinuations.forEach { $0.continuation.resume(throwing: EZChannelError.closed) }
    }
    
    private func setNextValue() {
        guard
            buffer.count < bufferSize,
            let (value, continuation) = continuations.setContinuations.tryRemoveFirst()
        else { return }
        buffer.append(value)
        continuation.resume()
    }
        
    private func checkIsClosed() throws {
        guard !isClosed else { throw EZChannelError.closed }
    }
    
    public init(){}
}

extension Array{
    public mutating func tryRemoveFirst() -> Element? {
        return isEmpty ? nil : removeFirst()
    }
}
