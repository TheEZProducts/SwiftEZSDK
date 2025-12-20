//
//  Array + ezBinarySearch.swift
//  EZSDK
//
//  Created by Александр Сенин on 20.12.2025.
//

import Foundation

extension Array {
    @discardableResult
    public mutating func ezBinaryRemove<V>(keyPath: KeyPath<Element, V>, value: V) -> Element? where V: Comparable {
        if let index = ezBinarySearch(keyPath: keyPath, value: value) { return remove(at: index) }
        return nil
    }
    
    public func ezBinarySearch<V>(keyPath: KeyPath<Element, V>, value: V) -> Int? where V: Comparable {
        var (leftIndex, rightIndex) = (0, count - 1)
        
        while leftIndex <= rightIndex {
            let middleIndex = (leftIndex + rightIndex) / 2
            let middleValue = self[middleIndex][keyPath: keyPath]
            
            if middleValue == value { return middleIndex }
            if value < middleValue {
                rightIndex = middleIndex - 1
            } else {
                leftIndex = middleIndex + 1
            }
        }
        return nil
    }
}
extension Array where Element: Comparable {
    public func ezBinarySearch(value: Element) -> Int? {
        ezBinarySearch(keyPath: \.self, value: value)
    }
}

