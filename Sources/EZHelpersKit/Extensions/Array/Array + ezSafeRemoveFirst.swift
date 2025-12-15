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
   
    /// Removes elements from the front until the first one that matches `predicate` and returns it.
    ///
    /// All elements before the matching one are discarded. Returns `nil` if no element matches.
    ///
    /// ### Example
    /// ```swift
    /// var xs: [Int?] = [nil, nil, 1, 2]
    /// let firstNonNil = xs.ezRemoveThroughFirst { $0 != nil } // Optional(1)
    /// // xs is now [Optional(2)]
    /// ```
    public mutating func ezRemoveThroughFirst(where predicate: (Element) -> Bool) -> Element? {
        while let first = ezSafeRemoveFirst() {
            if predicate(first) { return first }
        }
        return nil
    }
}
