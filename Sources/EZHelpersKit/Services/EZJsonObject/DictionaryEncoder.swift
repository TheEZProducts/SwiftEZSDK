//
//  DictionaryEncoder.swift
//  SwiftEZSDK
//
//  A tiny Encoder that converts Encodable values into Foundation-compatible
//  JSON-like trees: [String: Any], [Any], primitives, and NSNull.
//

import Foundation

// MARK: - Core encoder
/// Internal encoder used to build a JSON-like tree.
class _DictionaryEncoder: Encoder {

    // MARK: Storage

    var storage: _AnyStorage?

    // MARK: Encoder

    var codingPath: [CodingKey] { [] }
    var userInfo: [CodingUserInfoKey : Any]

    init(userInfo: [CodingUserInfoKey: Any] = [:]) {
        self.userInfo = userInfo
    }

    func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        let dict = _DictionaryStorage()
        self.storage = dict
        let container = _KeyedContainer<Key>(encoder: self, storage: dict)
        return KeyedEncodingContainer(container)
    }

    func unkeyedContainer() -> UnkeyedEncodingContainer {
        let array = _ArrayStorage()
        self.storage = array
        return _UnkeyedContainer(encoder: self, storage: array)
    }

    func singleValueContainer() -> SingleValueEncodingContainer {
        return self
    }

    func finalize() -> Any {
        // If nothing was encoded, mirror JSONEncoder behavior loosely by returning NSNull.
        return storage?.anyValue ?? NSNull()
    }
}

// MARK: - Storage types (reference semantics)

class _AnyStorage {
    var anyValue: Any { fatalError("Override") }
}

fileprivate final class _DictionaryStorage: _AnyStorage {
    var dict: [String: Any] = [:]
    override var anyValue: Any { dict }
}

fileprivate final class _ArrayStorage: _AnyStorage {
    var array: [Any] = []
    override var anyValue: Any { array }
}

fileprivate final class _SingleValueStorage: _AnyStorage {
    var value: Any
    init(_ value: Any) { self.value = value }
    override var anyValue: Any { value }
}

// MARK: - CodingKey helpers
struct _StringCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }

    init(_ string: String) {
        self.stringValue = string
    }

    init?(stringValue: String) {
        self.stringValue = stringValue
    }

    init?(intValue: Int) {
        return nil
    }
}

// MARK: - Referencing encoder

/// Encoder that writes its produced value back into a parent container on deinit.
///
/// This mirrors the strategy used by JSONEncoder internally: nested containers
/// need a place to write their result when the nested container/encoder is done.
fileprivate final class _ReferencingEncoder: _DictionaryEncoder {
    enum Reference {
        case dictionary(_DictionaryStorage, key: String)
        case array(_ArrayStorage, index: Int)
    }

    private let reference: Reference

    init(referencing parent: _DictionaryEncoder, reference: Reference) {
        self.reference = reference
        super.init(userInfo: parent.userInfo)
    }

    deinit {
        let value = finalize()
        switch reference {
        case .dictionary(let parent, let key):
            parent.dict[key] = value
        case .array(let parent, let index):
            if parent.array.indices.contains(index) {
                parent.array[index] = value
            } else {
                if index == parent.array.count {
                    parent.array.append(value)
                }
            }
        }
    }
}

// MARK: - Keyed container

fileprivate struct _KeyedContainer<K: CodingKey>: KeyedEncodingContainerProtocol {
    typealias Key = K
    
    private let encoder: _DictionaryEncoder
    private let storage: _DictionaryStorage

    var codingPath: [CodingKey] { [] }

    init(encoder: _DictionaryEncoder, storage: _DictionaryStorage) {
        self.encoder = encoder
        self.storage = storage
    }

    // Nil
    mutating func encodeNil(forKey key: Key) throws {
        storage.dict[key.stringValue] = NSNull()
    }

    // Primitives
    mutating func encode(_ value: Bool,   forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: String, forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: Double, forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: Float,  forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: Int,    forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: Int8,   forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: Int16,  forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: Int32,  forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: Int64,  forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: UInt,   forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: UInt8,  forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: UInt16, forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: UInt32, forKey key: Key) throws { storage.dict[key.stringValue] = value }
    mutating func encode(_ value: UInt64, forKey key: Key) throws { storage.dict[key.stringValue] = value }

    // Generic Encodable
    mutating func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
        let nested = _DictionaryEncoder(userInfo: encoder.userInfo)
        try value.encode(to: nested)
        storage.dict[key.stringValue] = nested.finalize()
    }

    // Nested containers
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let child = _DictionaryStorage()

        let ref = _ReferencingEncoder(
            referencing: encoder,
            reference: .dictionary(storage, key: key.stringValue)
        )
        ref.storage = child

        let container = _KeyedContainer<NestedKey>(encoder: ref, storage: child)
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let child = _ArrayStorage()

        let ref = _ReferencingEncoder(
            referencing: encoder,
            reference: .dictionary(storage, key: key.stringValue)
        )
        ref.storage = child

        return _UnkeyedContainer(encoder: ref, storage: child)
    }

    // super
    mutating func superEncoder() -> Encoder {
        // Same idea as JSONEncoder: provide a separate “slot” for super.
        // Use a stable key name.
        let key = "super"
        return _ReferencingEncoder(
            referencing: encoder,
            reference: .dictionary(storage, key: key)
        )
    }

    mutating func superEncoder(forKey key: Key) -> Encoder {
        _ReferencingEncoder(
            referencing: encoder,
            reference: .dictionary(storage, key: key.stringValue)
        )
    }
}

// MARK: - Unkeyed container

fileprivate struct _UnkeyedContainer: UnkeyedEncodingContainer {

    private let encoder: _DictionaryEncoder
    private let storage: _ArrayStorage

    init(encoder: _DictionaryEncoder, storage: _ArrayStorage) {
        self.encoder = encoder
        self.storage = storage
    }

    var codingPath: [CodingKey] { [] }
    var count: Int { storage.array.count }

    mutating func encodeNil() throws { storage.array.append(NSNull()) }

    mutating func encode(_ value: Bool)   throws { storage.array.append(value) }
    mutating func encode(_ value: String) throws { storage.array.append(value) }
    mutating func encode(_ value: Double) throws { storage.array.append(value) }
    mutating func encode(_ value: Float)  throws { storage.array.append(value) }
    mutating func encode(_ value: Int)    throws { storage.array.append(value) }
    mutating func encode(_ value: Int8)   throws { storage.array.append(value) }
    mutating func encode(_ value: Int16)  throws { storage.array.append(value) }
    mutating func encode(_ value: Int32)  throws { storage.array.append(value) }
    mutating func encode(_ value: Int64)  throws { storage.array.append(value) }
    mutating func encode(_ value: UInt)   throws { storage.array.append(value) }
    mutating func encode(_ value: UInt8)  throws { storage.array.append(value) }
    mutating func encode(_ value: UInt16) throws { storage.array.append(value) }
    mutating func encode(_ value: UInt32) throws { storage.array.append(value) }
    mutating func encode(_ value: UInt64) throws { storage.array.append(value) }

    mutating func encode<T>(_ value: T) throws where T : Encodable {
        let nested = _DictionaryEncoder(userInfo: encoder.userInfo)
        try value.encode(to: nested)
        storage.array.append(nested.finalize())
    }

    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
        let index = storage.array.count
        storage.array.append(NSNull()) // placeholder

        let child = _DictionaryStorage()

        let ref = _ReferencingEncoder(
            referencing: encoder,
            reference: .array(storage, index: index)
        )
        ref.storage = child

        let container = _KeyedContainer<NestedKey>(encoder: ref, storage: child)
        return KeyedEncodingContainer(container)
    }

    mutating func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let index = storage.array.count
        storage.array.append(NSNull()) // placeholder

        let child = _ArrayStorage()

        let ref = _ReferencingEncoder(
            referencing: encoder,
            reference: .array(storage, index: index)
        )
        ref.storage = child

        return _UnkeyedContainer(encoder: ref, storage: child)
    }

    mutating func superEncoder() -> Encoder {
        let index = storage.array.count
        storage.array.append(NSNull()) // placeholder

        return _ReferencingEncoder(
            referencing: encoder,
            reference: .array(storage, index: index)
        )
    }
}

extension _DictionaryEncoder: SingleValueEncodingContainer {
    func encodeNil() throws {
        storage = _SingleValueStorage(NSNull())
    }

    func encode(_ value: Bool) throws   { storage = _SingleValueStorage(value) }
    func encode(_ value: String) throws { storage = _SingleValueStorage(value) }
    func encode(_ value: Double) throws { storage = _SingleValueStorage(value) }
    func encode(_ value: Float) throws  { storage = _SingleValueStorage(value) }
    func encode(_ value: Int) throws    { storage = _SingleValueStorage(value) }
    func encode(_ value: Int8) throws   { storage = _SingleValueStorage(value) }
    func encode(_ value: Int16) throws  { storage = _SingleValueStorage(value) }
    func encode(_ value: Int32) throws  { storage = _SingleValueStorage(value) }
    func encode(_ value: Int64) throws  { storage = _SingleValueStorage(value) }
    func encode(_ value: UInt) throws   { storage = _SingleValueStorage(value) }
    func encode(_ value: UInt8) throws  { storage = _SingleValueStorage(value) }
    func encode(_ value: UInt16) throws { storage = _SingleValueStorage(value) }
    func encode(_ value: UInt32) throws { storage = _SingleValueStorage(value) }
    func encode(_ value: UInt64) throws { storage = _SingleValueStorage(value) }

    func encode<T>(_ value: T) throws where T : Encodable {
        let nested = _DictionaryEncoder(userInfo: userInfo)
        try value.encode(to: nested)
        storage = _SingleValueStorage(nested.finalize())
    }
}
