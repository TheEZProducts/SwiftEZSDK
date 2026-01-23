//
//  EZList.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.12.2025.
//

import Foundation

extension EZList {
    struct NodeStorage: ~Copyable {
        fileprivate var list: EZWeakWrapper<EZList<T>>
        fileprivate var next: Node?
        fileprivate var previous: Node?
    }
    
    /// A stable handle to an element stored inside `EZList`.
    ///
    /// `Item` gives you thread-safe access to the element's value and links to neighbouring
    /// items (`next` / `previous`). All mutations of `value` go through an internal `EZMutex`
    /// so it is safe to read/write from multiple threads.
    public struct Item: Sendable {
        fileprivate private(set) weak var _node: Node?
        
        nonisolated(unsafe)
        private let _value: EZMutex<T>
        
        /// The element's value.
        ///
        /// Reads and writes are synchronized via an internal `EZMutex`.
        public var value: T {
            get { _value.get() }
            nonmutating set { _value.set(newValue) }
        }
        
        /// The next item in the list, or `nil` if this is the tail or the node was detached.
        public var next: Item? { _node?.next?.item }
        /// The previous item in the list, or `nil` if this is the head or the node was detached.
        public var previous: Item? { _node?.previous?.item }
        
        /// Runs `body` with mutex-protected access to the underlying value.
        ///
        /// Use this for atomic read/modify/write operations on the element's value.
        ///
        /// ### Example
        /// ```swift
        /// item.update { access in
        ///     access.value += 1
        /// }
        /// ```
        public func update<R>(_ body: (borrowing EZBorrowedAccess<T>) throws -> R) rethrows -> R {
            try _value.withLock(body)
        }
        
        /// Inserts a new element **after** this item and returns the created item.
        ///
        /// Returns `nil` if the underlying node is no longer part of the list.
        public func insertAfter(_ value: T) -> Item? {
            _node?.insertAfter(value)
        }
        
        /// Inserts a new element **before** this item and returns the created item.
        ///
        /// Returns `nil` if the underlying node is no longer part of the list.
        public func insertBefore(_ value: T) -> Item? {
            _node?.insertBefore(value)
        }
        
        /// Removes this item from its list and returns its value.
        ///
        /// Returns `nil` if the node is no longer attached to the list.
        public func remove() -> T? {
            _node?.remove()
        }
        
        fileprivate init(node: Node, value: T) {
            _node = node
            _value = .init(value)
        }
    }
    
    fileprivate final class Node: Sendable {
        private let storage: EZMutex<NodeStorage>
        
        nonisolated(unsafe)
        private let _item: UnsafeMutablePointer<Item>
        fileprivate var item: Item { _read { yield _item.pointee } }
        
        fileprivate private(set) var list: EZList<T>? {
            get { storage.withLock { $0.value.list.value } }
            set { storage.withLock { $0.value.list = .init(value: newValue) } }
        }
        
        fileprivate var value: T {
            _read { yield _item.pointee.value }
            _modify { yield &_item.pointee.value }
        }
        
        fileprivate var next: Node? { storage.withLock { $0.value.next } }
        fileprivate var previous: Node? { storage.withLock { $0.value.previous } }
        
        fileprivate func update(next: Node?) {
            storage.withLock { $0.value.next = next }
        }
        
        fileprivate func update(previous: Node?) {
            storage.withLock { $0.value.previous = previous }
        }
        
        fileprivate func detach() -> (next: Node?, previous: Node?) {
            storage.withLock {
                let (next, previous) = ($0.value.next, $0.value.previous)
                $0.value.list = .init(value: nil)
                $0.value.next = nil
                $0.value.previous = nil
                next?.update(previous: previous)
                previous?.update(next: next)
                return (next, previous)
            }
        }
        
        fileprivate func insertAfter(_ value: T) -> Item? {
            list?.insert(value, afterNode: self)
        }
        
        fileprivate func insertBefore(_ value: T) -> Item? {
            list?.insert(value, beforeNode: self)
        }
        
        fileprivate func remove() -> T? {
            list?.remove(node: self)
        }
        
        fileprivate init(list: EZList<T>, value: T, next: Node? = nil, previous: Node? = nil) {
            self.storage = .init(.init(list: .init(value: list), next: next, previous: previous))
            self._item = .allocate(capacity: 1)
            self._item.initialize(to: .init(node: self, value: value))
        }
        
        deinit {
            _item.deinitialize(count: 1)
            _item.deallocate()
        }
    }
}

extension EZList {
    fileprivate struct Storage: ~Copyable {
        var count: Int = 0
        var head: Node?
        var tail: Node?
    }
}

/// A thread-safe doubly linked list with stable item handles.
///
/// `EZList` stores elements in a classic head/tail linked structure and synchronizes all
/// mutations with `EZMutex`. Each element is represented by a lightweight `Item` handle that
/// can be kept outside the list as long as the underlying node is still part of this list.
///
/// The list itself is `Sendable`, and `Item.value` access is also protected by a mutex, so
/// you can keep and mutate items across threads.
///
/// ### Example: basic usage
/// ```swift
/// let list = EZList<Int>()
///
/// let first = list.append(1)
/// let second = list.append(2)
/// list.prepend(0)
///
/// // Iterate over items
/// for item in list {
///     print(item.value)
/// }
///
/// // Atomically update an item's value
/// second.update { access in
///     access.value += 10
/// }
///
/// // Remove via handle
/// let removed = second.remove() // Optional(12)
/// ```
///
/// ### Example: working with `values`
/// ```swift
/// let list = EZList<String>()
/// list.append("a")
/// list.append("b")
///
/// for value in list.values {
///     print(value) // "a", "b"
/// }
/// ```
public final class EZList<T>: Sendable {
    private let storage = EZMutex(Storage())
    
    private func _remove(storage: inout Storage, node: Node) -> T? {
        guard node.list === self else { return nil }
        
        let (next, previous) = node.detach()
        if node === storage.head { storage.head = next }
        if node === storage.tail { storage.tail = previous }
        
        storage.count -= 1
        return node.value
    }
    
    private func _insert(_ value: T, storage: inout Storage, after previousNode: Node?, before nextNode: Node?) -> Item {
        let newNode = Node(list: self, value: value, next: nextNode, previous: previousNode)
       
        previousNode?.update(next: newNode)
        nextNode?.update(previous: newNode)

        if previousNode === storage.tail || storage.tail == nil { storage.tail = newNode }
        if nextNode === storage.head || storage.head == nil { storage.head = newNode }

        storage.count += 1
        return newNode.item
    }
    
    private func _validateNode(_ node: Node?) -> Node? {
        node?.list === self ? node : nil
    }
    
    public init() {}
}

extension EZList {
    /// Number of elements currently stored in the list.
    public var count: Int {
        storage.withLock { $0.value.count }
    }
    
    /// The first item in the list, or `nil` if the list is empty.
    public var head: Item? {
        storage.withLock { $0.value.head?.item }
    }
    /// The last item in the list, or `nil` if the list is empty.
    public var tail: Item? {
        storage.withLock { $0.value.tail?.item }
    }
}

extension EZList {
    /// Appends a new element to the end of the list.
    ///
    /// - Returns: The newly created item.
    @discardableResult
    public func append(_ value: T) -> Item {
        insert(value, afterNode: nil)
    }
    
    /// Inserts a new element at the beginning of the list.
    ///
    /// - Returns: The newly created item.
    @discardableResult
    public func prepend(_ value: T) -> Item {
        insert(value, beforeNode: nil)
    }
    
    /// Inserts a new element after the given item.
    ///
    /// If `item` is `nil` or no longer belongs to this list, the element is appended to the tail.
    ///
    /// - Returns: The newly created item.
    @discardableResult
    public func insert(_ value: T, after item: Item?) -> Item {
        insert(value, afterNode: item?._node)
    }
    
    /// Inserts a new element before the given item.
    ///
    /// If `item` is `nil` or no longer belongs to this list, the element is inserted at the head.
    ///
    /// - Returns: The newly created item.
    @discardableResult
    public func insert(_ value: T, before item: Item?) -> Item {
        insert(value, beforeNode: item?._node)
    }
    
    @discardableResult
    fileprivate func insert(_ value: T, afterNode: Node?) -> Item {
        return storage.withLock {
            let node = _validateNode(afterNode) ?? $0.value.tail
            return _insert(value, storage: &$0.value, after: node, before: node?.next)
        }
    }
    
    @discardableResult
    fileprivate func insert(_ value: T, beforeNode: Node?) -> Item {
        return storage.withLock {
            let node = _validateNode(beforeNode) ?? $0.value.head
            return _insert(value, storage: &$0.value, after: node?.previous, before: node)
        }
    }
}

extension EZList {
    /// Removes the first element from the list and returns its value.
    ///
    /// Returns `nil` if the list is empty.
    @discardableResult
    public func removeFirst() -> T? {
        storage.withLock {
            guard let head = $0.value.head else { return nil }
            return _remove(storage: &$0.value, node: head)
        }
    }
    
    /// Removes the last element from the list and returns its value.
    ///
    /// Returns `nil` if the list is empty.
    @discardableResult
    public func removeLast() -> T? {
        storage.withLock {
            guard let tail = $0.value.tail else { return nil }
            return _remove(storage: &$0.value, node: tail)
        }
    }
    
    /// Removes the given item from the list and returns its value.
    ///
    /// Returns `nil` if the item is no longer attached to this list.
    @discardableResult
    public func remove(item: Item) -> T? {
        guard let node = item._node else { return nil }
        return remove(node: node)
    }
    
    @discardableResult
    fileprivate func remove(node: Node) -> T? {
        storage.withLock { _remove(storage: &$0.value, node: node) }
    }
}

extension EZList {
    /// Returns the item if it still belongs to this list, otherwise `nil`.
    ///
    /// Useful when you keep `Item` handles across mutations and want to check that
    /// the underlying node has not been removed or moved to another list.
    @discardableResult
    public func validateItem(_ item: Item) -> Item? {
        guard
            let node = item._node,
            validateNode(node) != nil
        else { return nil }
        return item
    }
    
    fileprivate func validateNode(_ node: Node?) -> Node? {
        storage.withLock { _ in _validateNode(node) }
    }
    
    
    /// Returns the next item after the given one, or `nil` if there is none or the item is invalid.
    public func getNext(after item: Item) -> Item? {
        guard let node = item._node else { return nil }
        return getNext(after: node)?.item
    }
    
    /// Returns the previous item before the given one, or `nil` if there is none or the item is invalid.
    public func getPrevious(before item: Item) -> Item? {
        guard let node = item._node else { return nil }
        return getPrevious(before: node)?.item
    }
    
    fileprivate func getNext(after node: Node) -> Node? {
        storage.withLock { _ in _validateNode(node)?.next }
    }
    
    fileprivate func getPrevious(before node: Node) -> Node? {
        storage.withLock { _ in _validateNode(node)?.previous }
    }
}



// MARK: - Sequence

extension EZList: Sequence {
    /// Sequence of `Item` handles iterating from `head` to `tail`.
    public typealias Element = Item

    /// Iterator that walks the list from `head` to `tail`, skipping nodes that are no longer valid.
    public struct Iterator: IteratorProtocol {
        private let list: EZList<T>
        private var node: Node?

        fileprivate init(list: EZList<T>) {
            self.list = list
            self.node = list.storage.withLock { $0.value.head }
        }

        public mutating func next() -> Item? {
            guard let current = node else { return nil }

            // Stop if the node is no longer part of this list.
            guard list.validateNode(current) != nil else {
                node = nil
                return nil
            }

            let item = current.item
            node = list.getNext(after: current)
            return item
        }
    }

    /// Returns an iterator over all items currently in the list.
    public func makeIterator() -> Iterator {
        Iterator(list: self)
    }
}

extension EZList {
    /// A lazy sequence over the raw values stored in the list (ignores the `Item` wrapper).
    ///
    /// Equivalent to iterating over `self` and mapping `item.value`.
    public var values: AnySequence<T> {
        AnySequence {
            var iterator = self.makeIterator()
            return AnyIterator {
                iterator.next()?.value
            }
        }
    }
}
