//
//  Result + ezCortege.swift
//  EZSDK
//
//  Created by Александр Сенин on 14.12.2025.
//

import Foundation

extension Result {
    /// Returns a tuple view of the result as `(value, error)`.
    ///
    /// At most one of the components is non-`nil`:
    /// - on `.success`, `value` is set and `error` is `nil`;
    /// - on `.failure`, `error` is set and `value` is `nil`.
    ///
    /// This is convenient when you want to pass a single pair of optionals around instead of
    /// switching over `Result`.
    public var ezCortege: (value: Success?, error: Failure?) {
        switch self {
        case .success(let v): return (v, nil)
        case .failure(let e): return (nil, e)
        }
    }

    /// Creates a result from a `(value, error)` tuple.
    ///
    /// This is a thin convenience wrapper over `init?(value:error:)`.
    ///
    /// - Parameter cortege: A tuple where at most one component is expected to be non-`nil`.
    public init?(cortege: (Success?, Failure?)) {
        self.init(value: cortege.0, error: cortege.1)
    }

    /// Creates a `Result` from optional `value` and `error`.
    ///
    /// The initialization rules are:
    /// - if `value` is non-`nil`, the result becomes `.success(value)`;
    /// - else if `error` is non-`nil`, the result becomes `.failure(error)`;
    /// - else (both are `nil`) the initializer returns `nil`.
    ///
    /// If both `value` and `error` are non-`nil`, the `value` takes precedence.
    public init?(value: Success?, error: Failure?) {
        if let value {
            self = .success(value)
        } else if let error {
            self = .failure(error)
        } else {
            return nil
        }
    }
}
