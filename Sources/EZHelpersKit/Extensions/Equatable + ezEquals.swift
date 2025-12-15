//
//  Equatable + ezEquals.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.12.2025.
//

import Foundation

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
