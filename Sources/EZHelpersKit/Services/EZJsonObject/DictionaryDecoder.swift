//
//  DictionaryDecoder.swift
//  SwiftEZSDK
//
//  A tiny Decoder that decodes Foundation-compatible JSON-like trees produced by DictionaryEncoder:
//  [String: Any], [Any], primitives, and NSNull.
//

import Foundation

// MARK: - Lazy codingPath (persistent stack)

/// Linked-list node for a coding path. Building `[CodingKey]` is deferred until needed (usually only on errors).
final class _CodingPathNode {
    let parent: _CodingPathNode?
    let key: CodingKey

    init(parent: _CodingPathNode?, key: CodingKey) {
        self.parent = parent
        self.key = key
    }

    func toArray() -> [CodingKey] {
        // Build in reverse, then reverse once.
        var keys: [CodingKey] = []
        keys.reserveCapacity(8)
        var node: _CodingPathNode? = self
        while let n = node {
            keys.append(n.key)
            node = n.parent
        }
        keys.reverse()
        return keys
    }
}

fileprivate struct _IndexCodingKey: CodingKey {
    var intValue: Int?
    var stringValue: String

    init(_ index: Int) {
        self.intValue = index
        self.stringValue = String(index)
    }

    init?(intValue: Int) {
        self.init(intValue)
    }

    init?(stringValue: String) {
        guard let i = Int(stringValue) else { return nil }
        self.init(i)
    }
}

@inline(__always)
fileprivate func _pathArray(_ node: _CodingPathNode?, appending key: CodingKey? = nil) -> [CodingKey] {
    if node == nil {
        if let key { return [key] }
        return []
    }
    var arr = node!.toArray()
    if let key { arr.append(key) }
    return arr
}

// MARK: - Core decoder
final class _DictionaryDecoder: Decoder {

    fileprivate let value: Any
    fileprivate let pathNode: _CodingPathNode?

    /// Lazily materialized; in hot paths we do not build arrays.
    var codingPath: [CodingKey] { _pathArray(pathNode) }
    var userInfo: [CodingUserInfoKey : Any]

    init(value: Any = NSNull(), userInfo: [CodingUserInfoKey: Any] = [:], pathNode: _CodingPathNode? = nil) {
        self.value = value
        self.userInfo = userInfo
        self.pathNode = pathNode
    }

    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
        let dict: [String: Any] = try _tryCast([String: Any].self, value: value, codingPath: _pathArray(pathNode))
        let container = _KeyedDecodingContainer<Key>(decoder: self, container: dict, pathNode: pathNode)
        return KeyedDecodingContainer(container)
    }

    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let arr: [Any] = try _tryCast([Any].self, value: value, codingPath: _pathArray(pathNode))
        return _UnkeyedDecodingContainer(decoder: self, container: arr, pathNode: pathNode)
    }

    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return self
    }
}

// MARK: - Keyed container

private struct _KeyedDecodingContainer<K: CodingKey>: KeyedDecodingContainerProtocol {
    typealias Key = K

    private let decoder: _DictionaryDecoder
    private let container: [String: Any]
    private let pathNode: _CodingPathNode?

    init(decoder: _DictionaryDecoder, container: [String: Any], pathNode: _CodingPathNode?) {
        self.decoder = decoder
        self.container = container
        self.pathNode = pathNode
    }

    var codingPath: [CodingKey] { _pathArray(pathNode) }

    var allKeys: [Key] {
        container.keys.compactMap { Key(stringValue: $0) }
    }

    func contains(_ key: Key) -> Bool {
        container[key.stringValue] != nil
    }

    private func value(forKey key: Key) throws -> Any {
        guard let v = container[key.stringValue] else {
            throw DecodingError.keyNotFound(
                key,
                DecodingError.Context(codingPath: _pathArray(pathNode, appending: key), debugDescription: "No value associated with key \(key.stringValue).")
            )
        }
        return v
    }

    func decodeNil(forKey key: Key) throws -> Bool {
        guard let v = container[key.stringValue] else { return false }
        return v is NSNull
    }

    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        try _tryCast(type, value: try value(forKey: key), codingPath: _pathArray(pathNode, appending: key))
    }

    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
        let v = try value(forKey: key)
        let childNode = _CodingPathNode(parent: pathNode, key: key)
        let nested = _DictionaryDecoder(value: v, userInfo: decoder.userInfo, pathNode: childNode)
        return try T(from: nested)
    }

    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        let v = try value(forKey: key)
        let dict: [String: Any] = try _tryCast([String: Any].self, value: v, codingPath: _pathArray(pathNode, appending: key))
        let childNode = _CodingPathNode(parent: pathNode, key: key)
        return KeyedDecodingContainer(_KeyedDecodingContainer<NestedKey>(decoder: decoder, container: dict, pathNode: childNode))
    }

    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        let v = try value(forKey: key)
        let arr: [Any] = try _tryCast([Any].self, value: v, codingPath: _pathArray(pathNode, appending: key))
        let childNode = _CodingPathNode(parent: pathNode, key: key)
        return _UnkeyedDecodingContainer(decoder: decoder, container: arr, pathNode: childNode)
    }

    func superDecoder() throws -> Decoder {
        // Must match the encoder's stable key used by superEncoder().
        let superKey = _StringCodingKey(stringValue: "super")!
        let v = container["super"] ?? [:]
        let childNode = _CodingPathNode(parent: pathNode, key: superKey)
        return _DictionaryDecoder(value: v, userInfo: decoder.userInfo, pathNode: childNode)
    }

    func superDecoder(forKey key: Key) throws -> Decoder {
        let v = try value(forKey: key)
        let childNode = _CodingPathNode(parent: pathNode, key: key)
        return _DictionaryDecoder(value: v, userInfo: decoder.userInfo, pathNode: childNode)
    }
}

// MARK: - Unkeyed container

private struct _UnkeyedDecodingContainer: UnkeyedDecodingContainer {

    private let decoder: _DictionaryDecoder
    private let container: [Any]
    private let pathNode: _CodingPathNode?

    init(decoder: _DictionaryDecoder, container: [Any], pathNode: _CodingPathNode?) {
        self.decoder = decoder
        self.container = container
        self.pathNode = pathNode
    }

    var codingPath: [CodingKey] { _pathArray(pathNode) }

    var count: Int? { container.count }

    var currentIndex: Int = 0

    var isAtEnd: Bool {
        currentIndex >= (count ?? 0)
    }

    private func requireNotAtEnd(_ expected: Any.Type) throws {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(
                expected,
                DecodingError.Context(codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)), debugDescription: "Unkeyed container is at end.")
            )
        }
    }

    mutating func decodeNil() throws -> Bool {
        try requireNotAtEnd(Any.self)
        if container[currentIndex] is NSNull {
            currentIndex += 1
            return true
        }
        return false
    }

    mutating func decode(_ type: Bool.Type) throws -> Bool {
        try requireNotAtEnd(Bool.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: String.Type) throws -> String {
        try requireNotAtEnd(String.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: Double.Type) throws -> Double {
        try requireNotAtEnd(Double.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: Float.Type) throws -> Float {
        try requireNotAtEnd(Float.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: Int.Type) throws -> Int {
        try requireNotAtEnd(Int.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        try requireNotAtEnd(Int8.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        try requireNotAtEnd(Int16.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        try requireNotAtEnd(Int32.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        try requireNotAtEnd(Int64.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: UInt.Type) throws -> UInt {
        try requireNotAtEnd(UInt.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        try requireNotAtEnd(UInt8.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        try requireNotAtEnd(UInt16.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        try requireNotAtEnd(UInt32.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        try requireNotAtEnd(UInt64.self)
        defer { currentIndex += 1 }
        return try _tryCast(type, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
    }

    mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        try requireNotAtEnd(T.self)
        let v = container[currentIndex]
        let childNode = _CodingPathNode(parent: pathNode, key: _IndexCodingKey(currentIndex))
        currentIndex += 1
        let nested = _DictionaryDecoder(value: v, userInfo: decoder.userInfo, pathNode: childNode)
        return try T(from: nested)
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        try requireNotAtEnd([String: Any].self)
        defer { currentIndex += 1 }
        let dict: [String: Any] = try _tryCast([String: Any].self, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
        let childNode = _CodingPathNode(parent: pathNode, key: _IndexCodingKey(currentIndex))
        return KeyedDecodingContainer(_KeyedDecodingContainer<NestedKey>(decoder: decoder, container: dict, pathNode: childNode))
    }

    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        try requireNotAtEnd([Any].self)
        defer { currentIndex += 1 }
        let arr: [Any] = try _tryCast([Any].self, value: container[currentIndex], codingPath: _pathArray(pathNode, appending: _IndexCodingKey(currentIndex)))
        let childNode = _CodingPathNode(parent: pathNode, key: _IndexCodingKey(currentIndex))
        return _UnkeyedDecodingContainer(decoder: decoder, container: arr, pathNode: childNode)
    }

    mutating func superDecoder() throws -> Decoder {
        try requireNotAtEnd(Any.self)
        let v = container[currentIndex]
        let childNode = _CodingPathNode(parent: pathNode, key: _IndexCodingKey(currentIndex))
        currentIndex += 1
        return _DictionaryDecoder(value: v, userInfo: decoder.userInfo, pathNode: childNode)
    }
}

// MARK: - Single value container

extension _DictionaryDecoder: SingleValueDecodingContainer {

    func decodeNil() -> Bool {
        value is NSNull
    }

    func decode(_ type: Bool.Type) throws -> Bool {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: String.Type) throws -> String {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: Double.Type) throws -> Double {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: Float.Type) throws -> Float {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: Int.Type) throws -> Int {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: Int8.Type) throws -> Int8 {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: Int16.Type) throws -> Int16 {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: Int32.Type) throws -> Int32 {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: Int64.Type) throws -> Int64 {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: UInt.Type) throws -> UInt {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: UInt8.Type) throws -> UInt8 {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: UInt16.Type) throws -> UInt16 {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: UInt32.Type) throws -> UInt32 {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode(_ type: UInt64.Type) throws -> UInt64 {
        try _tryCast(type, value: value, codingPath: _pathArray(pathNode))
    }

    func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
        let nested = _DictionaryDecoder(value: value, userInfo: userInfo, pathNode: pathNode)
        return try T(from: nested)
    }
}

// MARK: - Casting helper

@inline(__always)
private func _tryCast<T>(_ asType: T.Type = T.self, value: Any, codingPath: @autoclosure () -> [CodingKey]) throws -> T {
    if let v = value as? T {
        return v
    }

    throw DecodingError.typeMismatch(
        asType,
        DecodingError.Context(
            codingPath: codingPath(),
            debugDescription: "Expected to decode \(asType) but found \(type(of: value)) instead."
        )
    )
}
