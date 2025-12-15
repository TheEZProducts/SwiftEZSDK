//
//  Array + initGroup.swift
//  EZSDK
//
//  Created by Александр Сенин on 13.12.2025.
//

import Foundation

extension Array{
    /// Flattens a variadic tuple into an `Array<Any>`.
    ///
    /// This initializer is a small convenience when you want to quickly pack several
    /// heterogenous values into an `[Any]` using variadic generics.
    ///
    /// ### Example
    /// ```swift
    /// let values: [Any] = .init(group: (1, "two", true))
    /// // values == [1, "two", true]
    /// ```
    public init<each T>(group: (repeat each T)) where Element == Any {
        var arr = [Any]()
        for element in repeat each group {
            arr.append(element)
        }
        self = arr
    }
    
    /// Flattens a variadic tuple into an array of `Element`, keeping only values that can be cast.
    ///
    /// Values in `group` that are not `Element` are skipped.
    ///
    /// ### Example
    /// ```swift
    /// let ints: [Int] = .init(as: Int.self, group: (1, "two", 3, 4.0))
    /// // ints == [1, 3]
    /// ```
    public init<each T>(as: Element.Type = Element.self, group: (repeat each T)) {
        var arr = [Element]()
        for element in repeat each group {
            if let element = element as? Element {
                arr.append(element)
            }
        }
        self = arr
    }
}

extension Array {
    /// Converts the array back into a variadic tuple of typed values.
    ///
    /// This is the inverse of the `init(group:)` helpers: given an array whose elements
    /// match the tuple types in `typs`, it reconstructs a `(repeat each T)` tuple.
    ///
    /// > Important: This function force-casts elements internally. It is the caller's
    /// > responsibility to ensure that the array actually contains values of the
    /// > expected types in the correct order.
    ///
    /// ### Example
    /// ```swift
    /// let values: [Any] = .init(group: (1, "two", true))
    /// let (int, string, flag): (Int, String, Bool) = values.ezConvertToGroup(typs: (Int.self, String.self, Bool.self))
    /// ```
    public func ezConvertToGroup<each T>(typs: repeat (each T).Type) -> (repeat each T) {
        var index: Int = 0
        return (repeat getNext(index: &index, as: (each T).self))
    }
    
    private func getNext<T>(index: inout Int, as type: T.Type = T.self) -> T {
        defer { index += 1 }
        return self[index] as! T
    }
}
