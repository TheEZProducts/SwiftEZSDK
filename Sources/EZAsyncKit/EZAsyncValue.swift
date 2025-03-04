//
//  AsyncValue.swift
//  Helpers
//
//  Created by Александр Сенин on 28.02.2025.
//

import Foundation

@available(macOS 10.15, *)
extension EZAsyncValue {
    actor Storage{
        private var value: Value?
        private var error: Error?
        
        private var continuations = [EZSafeContinuation<Value>]()
        
        func get() async throws -> Value {
            if let error = error {
                throw error
            }
            if let value = value {
                return value
            }
            return try await ezWithCheckedStoppableContinuation {
                continuations.append($0)
            }
        }
        
        func set(result: Result<Value, Error>){
            guard value == nil && error == nil else { return }
            switch result {
            case .success(let value):
                self.value = value
            case .failure(let error):
                self.error = error
            }
            continuations.forEach{ $0.resume(with: result) }
            continuations = []
        }
    }
}

@available(macOS 10.15, *)
final public class EZAsyncValue<Value: Sendable>: Sendable {
    private let storage = Storage()
    
    public func get() async throws -> Value {
        try await storage.get()
    }
    
    public init(action: (EZActionContinuation<Value>) -> ()) {
        let continuation = EZActionContinuation{[weak self] in
            await self?.storage.set(result: $0)
        }
    
        action(continuation)
    }
    
    public static func makeValue() -> (value: EZAsyncValue, continuation: EZActionContinuation<Value>) {
        var continuation: EZActionContinuation<Value>!
        let value = Self{
            continuation = $0
        }
        return (value, continuation)
    }
}

