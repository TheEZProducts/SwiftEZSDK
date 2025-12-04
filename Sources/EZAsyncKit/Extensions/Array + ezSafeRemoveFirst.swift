//
//  Array + ezSafeRemoveFirst.swift
//  EZSDK
//
//  Created by Александр Сенин on 03.12.2025.
//

import Foundation


extension Array {
    /// Removes and returns the first element, or `nil` if the array is empty.
    ///
    /// ### Example
    /// ```swift
    /// var xs = [1, 2, 3]
    /// print(xs.ezSafeRemoveFirst()) // Optional(1)
    /// print(xs)                    // [2, 3]
    ///
    /// var empty: [Int] = []
    /// print(empty.ezSafeRemoveFirst()) // nil
    /// ```
    public mutating func ezSafeRemoveFirst() -> Element? {
        return isEmpty ? nil : removeFirst()
    }
}

/// A lightweight error used by `Optional.ezUnwrap()`.
///
/// Note: `Equatable` conformance is intentionally trivial (all instances compare equal),
/// so you can compare errors in tests without caring about the message details.
public struct EZOptionalError: LocalizedError, Sendable, Equatable {
    private var text: String
    
    public init(text: String = "") { self.text = text }
    
    public static func == (lhs: Self, rhs: Self) -> Bool { true }
    
    /// Builds an error that includes file/function/line to help locate which value was `nil`.
    ///
    /// ### Example
    /// ```swift
    /// let err = EZOptionalError.isNil()
    /// print(err.localizedDescription)
    /// ```
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
    /// Unwraps the optional or throws.
    ///
    /// If `customError` is `nil`, throws `EZOptionalError.isNil(...)` with file/function/line context.
    ///
    /// ### Example
    /// ```swift
    /// let a: Int? = 42
    /// let v = try a.ezUnwrap() // 42
    ///
    /// let b: Int? = nil
    /// do {
    ///     _ = try b.ezUnwrap()
    /// } catch {
    ///     print(error.localizedDescription)
    /// }
    ///
    /// // Custom error:
    /// enum MyError: Error { case missing }
    /// _ = try b.ezUnwrap(MyError.missing)
    /// ```
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

/// A lightweight error used by `Equatable.ezEquals(with:)`.
///
/// Note: `Equatable` conformance is intentionally trivial (all instances compare equal).
public struct EZEquatableError: LocalizedError, Sendable, Equatable {
    private var text: String
    
    public init(text: String = "") { self.text = text }
    
    public static func == (lhs: Self, rhs: Self) -> Bool { true }
    
    /// Builds an error describing a mismatch (`v != v1`).
    ///
    /// ### Example
    /// ```swift
    /// let err = EZEquatableError.isNotEqual(v: 1, v1: 2)
    /// print(err.localizedDescription) // "EZEquatableError: 1 != 2"
    /// ```
    public static func isNotEqual<T: Equatable>(v: T, v1: T) -> EZEquatableError {
        EZEquatableError(text: "\(v) != \(v1)")
    }
    
    public var errorDescription: String? {
        "EZEquatableError: \(text)"
    }
}

extension Equatable {
    /// Throws if `self != value`.
    ///
    /// If `customError` is `nil`, throws `EZEquatableError.isNotEqual(v:v1:)`.
    ///
    /// ### Example
    /// ```swift
    /// try 10.ezEquals(with: 10) // ok
    ///
    /// do {
    ///     try 10.ezEquals(with: 11)
    /// } catch {
    ///     print(error.localizedDescription)
    /// }
    ///
    /// // Custom error:
    /// enum MyError: Error { case mismatch }
    /// try 10.ezEquals(with: 11, MyError.mismatch)
    /// ```
    public func ezEquals(with value: Self, _ customError: Error? = nil) throws {
        guard self == value else {
            throw customError ?? EZEquatableError.isNotEqual(v: self, v1: value)
        }
    }
}
