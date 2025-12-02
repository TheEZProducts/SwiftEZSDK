//
//  EZChannel.swift
//  EZSDK
//
//  Created by Александр Сенин on 05.05.2025.
//

import Foundation

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZChannel<T: Sendable> {
    private var continuations = (
        setContinuations: [EZSafeContinuation<EZSafeContinuation<T>>](),
        getContinuations: [EZSafeContinuation<T>]()
    )
    
    public func get() async throws -> T {
        try await ezWithCheckedStoppableContinuation { getContinuation in
            if let continuation = continuations.setContinuations.tryRemoveFirst(){
                continuation.resume(returning: getContinuation)
            }else{
                continuations.getContinuations.append(getContinuation)
            }
        }
    }
    
    public func set(_ value: T) async {
        try? await ezWithCheckedStoppableContinuation { continuation in
            if let getContinuation = continuations.getContinuations.tryRemoveFirst(){
                continuation.resume(returning: getContinuation)
            } else {
                continuations.setContinuations.append(continuation)
            }
        }.resume(returning: value)
    }
    
    public init(){}
}

extension Array{
    public mutating func tryRemoveFirst() -> Element? {
        return isEmpty ? nil : removeFirst()
    }
}
