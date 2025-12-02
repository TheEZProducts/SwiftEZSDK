//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

protocol EZThreadSafetyIsolatedValueProtocol<Value>: Sendable{
    associatedtype Value
    
    @discardableResult
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func update<Result: Sendable>(_ closure: @Sendable (inout Value) throws -> (Result)) async rethrows -> Result
    
    @discardableResult
    func update<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
actor ActorIsolatedValue<Value>: EZThreadSafetyIsolatedValueProtocol{
    private let semaphore = DispatchSemaphore(value: 1)
    
    private nonisolated(unsafe) var value: Value
    
    @discardableResult
    nonisolated func update<Result: Sendable>(_ closure: @Sendable (inout Value) throws -> (Result)) async rethrows -> Result{
        try await isolatedUpdate(closure)
    }
    
    @discardableResult
    private func isolatedUpdate<Result: Sendable>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result{
        try updateAction(closure)
    }
    
    @discardableResult
    nonisolated func update<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result{
        try updateAction(closure)
    }
    
    @discardableResult
    private nonisolated func updateAction<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result{
        semaphore.wait(); defer { semaphore.signal() }
        return try closure(&value)
    }
    
    init(value: Value) {
        self.value = value
    }
}

final class SemaphoreIsolatedValue<Value>: EZThreadSafetyIsolatedValueProtocol{
    private let semaphore = DispatchSemaphore(value: 1)
    
    private nonisolated(unsafe) var value: Value
    
    @discardableResult
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func update<Result: Sendable>(_ closure: @Sendable (inout Value) throws -> (Result)) async rethrows -> Result{
        try updateAction(closure)
    }
    
    @discardableResult
    func update<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result{
        try updateAction(closure)
    }
    
    @discardableResult
    private func updateAction<Result>(_ closure: (inout Value) throws -> (Result)) rethrows -> Result{
        semaphore.wait(); defer { semaphore.signal() }
        return try closure(&value)
    }
    
    init(value: Value) {
        self.value = value
    }
}

 
@propertyWrapper
public struct EZThreadSafety<Value: Sendable>: Sendable {
    private let value: (any EZThreadSafetyIsolatedValueProtocol<Value>)
    
    @available(*, noasync, message: "use let value = await $property.get() or await $property.set(value)")
    public var wrappedValue: Value {
        set(value) {
            self.value.update{ $0 = value }
        }
        get {
            return value.update{ $0 }
        }
    }
    
    public var projectedValue: Self { self }
    
    @discardableResult
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func update<Result: Sendable>(_ closure: @Sendable (inout Value) throws -> (Result)) async rethrows -> Result{
        try await value.update(closure)
    }
    
    @discardableResult
    @available(*, noasync, message: "use await $property.update")
    public func update<Result>(_ closure: @Sendable (inout Value) throws -> (Result)) rethrows -> Result{
        try value.update(closure)
    }
    
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func set(_ value: Value) async {
        await update{ $0 = value }
    }
    
    @available(*, noasync, message: "use await $property.set")
    public func set(_ value: Value) {
        update{ $0 = value }
    }
    
    @discardableResult
    @_disfavoredOverload
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    public func get() async -> Value{
        await update{ $0 }
    }
    
    @discardableResult
    @available(*, noasync, message: "use await $property.get")
    public func get() -> Value{
        update{ $0 }
    }
    
    public init(wrappedValue: Value){
        if #available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *) {
            self.value = ActorIsolatedValue(value: wrappedValue)
        } else {
            self.value = SemaphoreIsolatedValue(value: wrappedValue)
        }
    }
}

