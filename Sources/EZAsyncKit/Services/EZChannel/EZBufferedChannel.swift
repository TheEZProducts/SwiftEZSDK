//
//  EZBufferedChannel.swift
//  EZSDK
//
//  Created by Александр Сенин on 03.12.2025.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZBufferedChannel<T: Sendable> {
    public private(set) var isClosed: Bool = false
    
    private var bufferSize: Int { buffer.capacity }
    private var buffer: [T] = []
    
    public init(bufferSize: Int) {
        buffer = .init(unsafeUninitializedCapacity: max(1, bufferSize), initializingWith: {_,_ in})
    }
    
    private var continuations = (
        setContinuations: [(value: T, continuation: EZSafeContinuation<Void>)](),
        getContinuations: [EZSafeContinuation<T>]()
    )
    
    public func get() async throws -> T {
        try checkIsClosed()
        if let value = buffer.ezSafeRemoveFirst() {
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
        if let getContinuation = continuations.getContinuations.ezSafeRemoveFirst() {
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
            let (value, continuation) = continuations.setContinuations.ezSafeRemoveFirst()
        else { return }
        buffer.append(value)
        continuation.resume()
    }
        
    public func checkIsClosed() throws {
        guard !isClosed else { throw EZChannelError.closed }
    }
    
    public init(){}
}
