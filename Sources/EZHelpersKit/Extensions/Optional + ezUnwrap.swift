//
//  Optional + .swift
//  EZSDK
//
//  Created by Александр Сенин on 07.12.2025.
//

import Foundation

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
        line: UInt = #line
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
