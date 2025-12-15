//
//  Result + ezGetError.swift
//  EZSDK
//
//  Created by Александр Сенин on 13.12.2025.
//

import Foundation

extension Result {
    /// Returns the associated error if the result is `.failure`, otherwise `nil`.
    ///
    /// This is a tiny convenience helper to avoid `switch`ing when you only care about the error.
    ///
    /// ### Example
    /// ```swift
    /// let ok: Result<Int, NSError> = .success(1)
    /// let failed: Result<Int, NSError> = .failure(NSError(domain: "test", code: 1))
    ///
    /// print(ok.ezGetError() == nil)       // true
    /// print(failed.ezGetError() != nil)   // true
    /// ```
    public func ezGetError() -> Failure? {
        switch self{
        case .failure(let error):
            return error
        default:
            return nil
        }
    }
}
