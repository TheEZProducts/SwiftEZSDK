//
//  Array + ezSafeRemoveFirst.swift
//  EZSDK
//
//  Created by Александр Сенин on 03.12.2025.
//

import Foundation

extension Array {
    public mutating func ezSafeRemoveFirst() -> Element? {
        return isEmpty ? nil : removeFirst()
    }
}

public struct EZOptionalError: LocalizedError, Sendable, Equatable {
    private var text: String
    
    public init(text: String = "") { self.text = text }
    
    public static func == (lhs: Self, rhs: Self) -> Bool { true }
    
    public static func isNil(
        file: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line,
    ) -> EZOptionalError {
        EZOptionalError(text: "Value is nil, file: \(file), function: \(functionName), line: \(line)")
    }
    
    public var errorDescription: String? {
        "EZOptionalError: \(text)"
    }
}

extension Optional {
    public func ezUnwrap(
        file: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line,
        _ customError: Error? = nil) throws -> Wrapped {
        guard let unwrapped = self else {
            throw customError ?? EZOptionalError.isNil(file: file, functionName: functionName, line: line)
        }
        return unwrapped
    }
}

public struct EZEquatableError: LocalizedError, Sendable, Equatable {
    private var text: String
    
    public init(text: String = "") { self.text = text }
    
    public static func == (lhs: Self, rhs: Self) -> Bool { true }
    
    public static func isNotEqual<T: Equatable>(v: T, v1: T) -> EZEquatableError {
        EZEquatableError(text: "\(v) != \(v1)")
    }
    
    public var errorDescription: String? {
        "EZEquatableError: \(text)"
    }
}

extension Equatable {
    public func ezEquals(with value: Self, _ customError: Error? = nil) throws {
        guard self == value else {
            throw customError ?? EZEquatableError.isNotEqual(v: self, v1: value)
        }
    }
}
