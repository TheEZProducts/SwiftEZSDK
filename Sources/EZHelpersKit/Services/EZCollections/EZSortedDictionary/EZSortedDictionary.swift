//
//  EZSortedDictionary.swift
//  LocalHelpers
//
//  Created by Александр Сенин on 09.05.2025.
//

import Foundation

extension EZSortedDictionary {
    /// A key–value pair stored inside `EZSortedDictionary`.
    ///
    /// This type is used as the element type when iterating the dictionary and as the underlying
    /// storage unit for sorted elements.
    public struct Pair {
        public let key: Key
        public var value: Value
        
        public init(key: Key, value: Value) {
            self.key = key
            self.value = value
        }
    }
}
/// A lightweight sorted dictionary backed by an array of key–value pairs.
///
/// Keys are kept in ascending order (`Key: Comparable`) and lookups are performed via binary search.
/// This makes it convenient for small to medium collections where you want deterministic order,
/// cheap iteration, and range queries over keys.
///
/// ### Example
/// ```swift
/// var dict = EZSortedDictionary<String, Int>()
///
/// dict["b"] = 2
/// dict["a"] = 1
/// dict["c"] = 3
///
/// print(dict.keys)   // ["a", "b", "c"]
/// print(dict.values) // [1, 2, 3]
///
/// // Update and remove
/// let old = dict.updateValue(10, forKey: "b") // old == Optional(2)
/// dict["c"] = nil                             // remove key "c"
/// ```
///
/// ### Example: range query
/// ```swift
/// let scores: EZSortedDictionary<Int, String> = [
///     10: "low",
///     20: "medium",
///     30: "high"
/// ]
///
/// let midRange = scores.range(15, 30)
/// // contains pairs for keys 20 and 30
/// ```
public struct EZSortedDictionary<Key: Comparable, Value> {
    /// Underlying storage of sorted key–value pairs.
    ///
    /// You typically interact with the dictionary via subscripts and helpers instead of
    /// mutating `elements` directly.
    public private(set) var elements: [Pair] = []

    /// Number of key–value pairs in the dictionary.
    public var count: Int { elements.count }
    
    /// Creates an empty sorted dictionary.
    public init() {}
    
    /// Creates a dictionary from an already-sorted array of pairs.
    ///
    /// - Important: The caller is responsible for ensuring that `elements` are sorted
    ///   by key in ascending order.
    public init(sorted elements: [Pair]) {
        self.elements = elements
    }
    
    /// Creates a dictionary from an unsorted array of pairs, sorting them by key.
    public init(elements: [Pair]) {
        self.elements = elements.sorted { $0.key < $1.key }
    }

    /// All keys in ascending order.
    public var keys: [Key] {
        elements.map { $0.key }
    }

    /// All values in the order of their sorted keys.
    public var values: [Value] {
        elements.map { $0.value }
    }

    /// The smallest key–value pair, or `nil` if the dictionary is empty.
    public var first: Pair? {
        elements.first
    }

    /// The largest key–value pair, or `nil` if the dictionary is empty.
    public var last: Pair? {
        elements.last
    }

    /// Accesses the value associated with the given key.
    ///
    /// Setting the value to `nil` removes the key from the dictionary.
    ///
    /// - Parameter key: A comparable key.
    /// - Returns: The value for `key`, or `nil` if the key is not present.
    public subscript(_ key: Key) -> Value? {
        get {
            guard let idx = index(of: key) else { return nil }
            return elements[idx].value
        }
        set {
            let index = insertionIndex(for: key)
            if elements[ezSafe: index]?.key == key {
                if let v = newValue {
                    elements[index].value = v
                } else {
                    elements.remove(at: index)
                }
            } else if let v = newValue {
                elements.insert(Pair(key: key, value: v), at: index)
            }
        }
    }

    /// Accesses the value at a given position in the sorted order.
    ///
    /// - Parameter index: A zero-based index into the sorted storage.
    /// - Precondition: `index` must be a valid index in `0..<count`.
    @_disfavoredOverload
    public subscript(position index: Int) -> Value {
        get {
            elements[index].value
        }
        set {
            elements[index].value = newValue
        }
    }

    /// Safely accesses or mutates the value at a given position.
    ///
    /// - If `index` is out of bounds, `get` returns `nil` and `set` is ignored.
    /// - Setting `nil` removes the element at `index` when it exists.
    @_disfavoredOverload
    public subscript(safePosition index: Int) -> Value? {
        get {
            guard elements.indices.contains(index) else { return nil }
            return elements[index].value
        }
        set {
            guard elements.indices.contains(index) else { return }
            if let v = newValue {
                elements[index].value = v
            } else {
                elements.remove(at: index)
            }
        }
    }

    /// Removes all key–value pairs from the dictionary.
    public mutating func removeAll() {
        elements.removeAll()
    }

    /// Updates the value for `key` and returns the previous value, if any.
    ///
    /// Mirrors `Dictionary.updateValue(_:forKey:)` semantics.
    @discardableResult
    public mutating func updateValue(_ value: Value, forKey key: Key) -> Value? {
        let old = self[key]
        self[key] = value
        return old
    }

    /// Removes the pair with the given key and returns it.
    ///
    /// - Returns: The removed pair, or `nil` if the key was not present.
    @discardableResult
    public mutating func remove(key: Key) -> Pair? {
        guard let index = index(of: key) else { return nil }
        return elements.remove(at: index)
    }

    /// Removes and returns the pair at a specific index in the sorted order.
    ///
    /// - Precondition: `index` must be a valid index in `0..<count`.
    @discardableResult
    public mutating func remove(at index: Int) -> Pair {
        elements.remove(at: index)
    }

    /// Removes and returns the first (smallest key) pair.
    ///
    /// - Precondition: The dictionary must not be empty.
    @discardableResult
    public mutating func removeFirst() -> Pair {
        elements.removeFirst()
    }

    /// Removes and returns the last (largest key) pair.
    ///
    /// - Precondition: The dictionary must not be empty.
    @discardableResult
    public mutating func removeLast() -> Pair {
        elements.removeLast()
    }

    /// Removes and returns the first pair, or `nil` if the dictionary is empty.
    public mutating func popFirst() -> Pair? {
        elements.isEmpty ? nil : elements.removeFirst()
    }

    /// Removes and returns the last pair, or `nil` if the dictionary is empty.
    public mutating func popLast() -> Pair? {
        elements.isEmpty ? nil : elements.removeLast()
    }

    /// Returns a copy of the dictionary without the first `n` pairs.
    public func dropFirst(_ n: Int) -> EZSortedDictionary {
        var result = self
        if n >= result.elements.count {
            result.elements.removeAll()
        } else {
            result.elements.removeFirst(n)
        }
        return result
    }

    /// Returns a copy of the dictionary without the last `n` pairs.
    public func dropLast(_ n: Int) -> EZSortedDictionary {
        var result = self
        if n >= result.elements.count {
            result.elements.removeAll()
        } else {
            result.elements.removeLast(n)
        }
        return result
    }

    /// Removes the first `n` pairs, or clears the dictionary if `n >= count`.
    public mutating func removeFirst(_ n: Int) {
        if n >= elements.count {
            elements.removeAll()
        } else {
            elements.removeFirst(n)
        }
    }

    /// Removes the last `n` pairs, or clears the dictionary if `n >= count`.
    public mutating func removeLast(_ n: Int) {
        if n >= elements.count {
            elements.removeAll()
        } else {
            elements.removeLast(n)
        }
    }

    /// Finds the index of a key using binary search.
    ///
    /// - Parameter key: The key to search for.
    /// - Returns: The index of the key in the sorted storage, or `nil` if not found.
    public func index(of key: Key) -> Int? {
        var low = 0, high = elements.count - 1
        while low <= high {
            let mid = (low + high) / 2
            if elements[mid].key == key {
                return mid
            } else if elements[mid].key < key {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }
        return nil
    }

    private func insertionIndex(for key: Key) -> Int {
        var low = 0, high = elements.count
        while low < high {
            let mid = (low + high) / 2
            if elements[mid].key < key {
                low = mid + 1
            } else {
                high = mid
            }
        }
        return low
    }

    /// Returns a new dictionary that contains the union of `self` and `other`.
    ///
    /// Values from `other` overwrite values for matching keys in `self`.
    public func union(_ other: EZSortedDictionary) -> EZSortedDictionary {
        var result = self
        for pair in other.elements {
            result[pair.key] = pair.value
        }
        return result
    }

    /// Returns a new dictionary containing only keys that exist in both `self` and `other`.
    ///
    /// Values are taken from `self`.
    public func intersection(_ other: EZSortedDictionary) -> EZSortedDictionary {
        var result = EZSortedDictionary()
        for pair in elements where other[pair.key] != nil {
            result[pair.key] = pair.value
        }
        return result
    }

    /// Returns the union of two sorted dictionaries (`lhs` and `rhs`).
    public static func + (lhs: EZSortedDictionary<Key, Value>, rhs: EZSortedDictionary<Key, Value>) -> EZSortedDictionary<Key, Value> {
        return lhs.union(rhs)
    }

    /// In-place union assignment. Values from `rhs` overwrite any existing values in `lhs`.
    public static func += (lhs: inout EZSortedDictionary<Key, Value>, rhs: EZSortedDictionary<Key, Value>) {
        lhs = lhs.union(rhs)
    }

    /// Returns a new dictionary by removing all keys found in `other` from `self`.
    public func subtracting(_ other: EZSortedDictionary) -> EZSortedDictionary {
        var result = self
        for pair in other.elements {
            result[pair.key] = nil
        }
        return result
    }

    /// Returns a dictionary built by subtracting all keys of `rhs` from `lhs`.
    public static func - (lhs: EZSortedDictionary<Key, Value>, rhs: EZSortedDictionary<Key, Value>) -> EZSortedDictionary<Key, Value> {
        lhs.subtracting(rhs)
    }

    /// In-place subtraction assignment: removes all keys from `lhs` that exist in `rhs`.
    public static func -= (lhs: inout EZSortedDictionary<Key, Value>, rhs: EZSortedDictionary<Key, Value>) {
        lhs = lhs.subtracting(rhs)
    }

    /// Returns all pairs whose keys fall within the closed range `[lowerBound, upperBound]`.
    ///
    /// Keys are included if `lowerBound <= key <= upperBound`.
    public func range(_ lowerBound: Key, _ upperBound: Key) -> [Pair] {
        let start = insertionIndex(for: lowerBound)
        var end = insertionIndex(for: upperBound)
        if let eq = index(of: upperBound) {
            end = eq + 1
        }
        return Array(elements[start..<Swift.min(end, elements.count)])
    }

    /// Accesses all pairs whose keys lie within the given closed key range.
    ///
    /// Equivalent to `range(range.lowerBound, range.upperBound)`, but returns a slice view.
    public subscript(_ range: ClosedRange<Key>) -> ArraySlice<Pair> {
        let start = insertionIndex(for: range.lowerBound)
        var end = insertionIndex(for: range.upperBound)
        if let eq = index(of: range.upperBound) {
            end = eq + 1
        }
        return elements[start..<Swift.min(end, elements.count)]
    }

    /// Accesses all pairs whose keys lie within the given half-open key range.
    ///
    /// Keys satisfy `range.lowerBound <= key < range.upperBound`.
    public subscript(_ range: Range<Key>) -> ArraySlice<Pair> {
        let start = insertionIndex(for: range.lowerBound)
        let end = insertionIndex(for: range.upperBound)
        return elements[start..<Swift.min(end, elements.count)]
    }
}

extension EZSortedDictionary: ExpressibleByDictionaryLiteral {
    /// Creates a sorted dictionary from a dictionary literal.
    ///
    /// Duplicate keys keep the value from the last occurrence in the literal.
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init()
        for (k, v) in elements {
            self[k] = v
        }
    }
}

extension EZSortedDictionary: Sequence {
    /// Sequence element type: each iteration yields a `Pair` in sorted key order.
    public typealias Element = Pair
    /// Returns an iterator over all pairs in ascending key order.
    public func makeIterator() -> IndexingIterator<[Pair]> {
        elements.makeIterator()
    }
}

// MARK: - Collection Conformance
extension EZSortedDictionary: Collection, MutableCollection, RandomAccessCollection {
    public typealias Index = Int
    /// The position of the first pair in the collection (same as in the underlying storage).
    public var startIndex: Int { elements.startIndex }
    /// The position one past the last valid subscript argument.
    public var endIndex: Int { elements.endIndex }
    /// Returns the index immediately after `i`.
    public func index(after i: Int) -> Int { elements.index(after: i) }
    
    /// Accesses the pair at the given position in the collection view.
    @_disfavoredOverload
    public subscript(position: Int) -> Pair {
        get { elements[position] }
        set { elements[position] = newValue }
    }
}


extension EZSortedDictionary: Sendable where Key: Sendable, Value: Sendable {}
extension EZSortedDictionary: Equatable where Key: Equatable, Value: Equatable {}
extension EZSortedDictionary: Hashable where Key: Hashable, Value: Hashable {}
extension EZSortedDictionary: Codable where Key: Codable, Value: Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(elements)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let pairs = try container.decode([Pair].self)
        self.init()
        self.elements = pairs.sorted { $0.key < $1.key }
    }
}


extension EZSortedDictionary.Pair: Sendable where Key: Sendable, Value: Sendable {}
extension EZSortedDictionary.Pair: Equatable where Key: Equatable, Value: Equatable {}
extension EZSortedDictionary.Pair: Hashable where Key: Hashable, Value: Hashable {}
extension EZSortedDictionary.Pair: Codable where Key: Codable, Value: Codable {}

