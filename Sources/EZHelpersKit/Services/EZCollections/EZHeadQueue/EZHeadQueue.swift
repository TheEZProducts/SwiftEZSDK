//
//  EZHeadQueue.swift
//  EZSDK
//
//  Created by Александр Сенин on 12.12.2025.
//

import Foundation

/// A simple FIFO queue optimized for cheap `dequeue` operations.
///
/// `EZHeadQueue` keeps a moving `head` index into an array and periodically compacts storage
/// to avoid unbounded growth. This makes `enqueue`/`dequeue` amortized O(1) without constantly
/// shifting elements.
///
/// The queue stores elements in-order and exposes `RandomAccessCollection` conformance so you can
/// inspect its contents without mutating it.
///
/// ### Example
/// ```swift
/// var queue = EZHeadQueue<Int>()
/// queue.enqueue(1)
/// queue.enqueue(2)
///
/// print(queue.dequeue()) // Optional(1)
/// print(queue.dequeue()) // Optional(2)
/// print(queue.dequeue()) // nil
/// ```
public struct EZHeadQueue<Element> {
    private var storage: [Element?] = []
    private var head: Int = 0

    private let compactAfter: Int

    /// Creates an empty queue.
    ///
    /// - Parameter compactAfter: Number of consumed elements after which the underlying storage
    ///   is compacted. You usually do not need to tweak this.
    public init(compactAfter: Int = 1024) {
        self.compactAfter = compactAfter
    }

    /// Returns `true` when the queue has no elements.
    public var isEmpty: Bool { count == 0 }
    /// Number of elements currently in the queue.
    public var count: Int { storage.count - head }

    /// Appends an element to the back of the queue.
    public mutating func enqueue(_ x: Element) {
        storage.append(x)
    }

    /// Removes and returns the element at the front of the queue, or `nil` if it is empty.
    public mutating func dequeue() -> Element? {
        guard head < storage.count, let x = storage[head] else {
            if head < storage.count { head += 1; compactIfNeeded() }
            return nil
        }
        storage[head] = nil
        head += 1
        compactIfNeeded()
        return x
    }
    
    private mutating func compactIfNeeded() {
        if count == 0 { head = 0; storage = []; return }
        guard head >= compactAfter else { return }
        storage.removeFirst(head)
        head = 0
    }
}

extension EZHeadQueue: Sendable where Element: Sendable {}

extension EZHeadQueue: ExpressibleByArrayLiteral {
    /// Creates a queue prefilled with the given elements.
    ///
    /// The first literal element becomes the head of the queue.
    public init(arrayLiteral elements: Element...) {
        self.init()
        storage = elements
    }
}

extension EZHeadQueue {
    /// Dequeues elements until the first one that matches `predicate` and returns it.
    ///
    /// All elements before the matching one are discarded. Returns `nil` if no element matches.
    ///
    /// ### Example: skipping `nil` values
    /// ```swift
    /// var q: EZHeadQueue<Int?> = [nil, nil, 1, nil, 2]
    /// let firstNonNil = q.dequeueThroughFirst { $0 != nil }
    /// // All leading `nil` elements are removed; `firstNonNil` wraps `1`.
    /// ```
    public mutating func dequeueThroughFirst(where predicate: (Element) -> Bool) -> Element? {
        while let first = dequeue() {
            if predicate(first) { return first }
        }
        return nil
    }
}

extension EZHeadQueue: RandomAccessCollection {
    public typealias Index = Int

    public var startIndex: Int { 0 }
    public var endIndex: Int { count }

    public func index(after i: Int) -> Int {
        precondition(i < endIndex, "Index out of bounds")
        return i + 1
    }

    public func index(before i: Int) -> Int {
        precondition(i > startIndex, "Index out of bounds")
        return i - 1
    }

    /// Accesses the element at `position` without removing it.
    ///
    /// Indices are zero-based and relative to the current head of the queue.
    public subscript(position: Int) -> Element {
        precondition(position >= startIndex && position < endIndex, "Index out of bounds")
        guard let x = storage[head + position] else {
            preconditionFailure("Corrupted queue state: nil in active range")
        }
        return x
    }
}
