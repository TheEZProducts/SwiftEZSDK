//
//  Collection + ezSafeIndex.swift
//  EZSDK
//
//  Created by Александр Сенин on 13.12.2025.
//

import Foundation

extension Collection {
    /// Safely returns the element at `index`, or `nil` if it is out of bounds.
    ///
    /// This is a convenience wrapper that avoids a runtime crash when using an index that is
    /// greater than or equal to `endIndex`.
    ///
    /// ### Example
    /// ```swift
    /// let array = [1, 2, 3]
    /// print(array[ezSafe: 1]) // Optional(2)
    /// print(array[ezSafe: 10]) // nil
    /// ```
    public subscript(ezSafe index: Index) -> Element? {
        index < endIndex ? self[index] : nil
    }
}
