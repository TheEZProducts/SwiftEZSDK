//
//  File.swift
//
//
//  Created by Александр Сенин on 11.06.2024.
//

import Foundation

struct CKey: CodingKey {
    var stringValue: String
    var intValue: Int? { Int(stringValue) }
    
    init(_ stringValue: String) {
        self.stringValue = stringValue
    }
    init(_ intValue: Int) {
        stringValue = "\(intValue)"
    }
    
    init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    init?(intValue: Int) {
        stringValue = "\(intValue)"
    }
}

protocol NSNumberCodableProtocol: Codable {}

extension NSNumberCodableProtocol {
    public func encode(to encoder: Encoder) throws where Self: NSNumber {
        var container = encoder.singleValueContainer()
        try container.encode(self.doubleValue)
    }
    
    public init(from decoder: Decoder) throws where Self: NSNumber {
        self = .init(floatLiteral: try (decoder.singleValueContainer()).decode(Double.self))
    }
}

extension NSNumber: @retroactive Codable {}
extension NSNumber: NSNumberCodableProtocol {}

/// A dynamic JSON value wrapper backed by `Any`.
///
/// `EZJsonObject` is a small helper for working with loosely-typed JSON:
/// - You can store any JSON-compatible value in `value`.
/// - It conforms to `Codable` and can encode/decode nested dictionaries and arrays.
/// - It supports literal initialization (string, number, bool, array, dictionary).
///
/// The main use case is to replace `Any` in `Codable` types when the JSON shape is not known at compile time.
/// Instead of `Any`, store an `EZJsonObject`, and later convert it into a strongly-typed model with `convert(to:)`.
///
/// ### Examples
/// ```swift
/// // Dynamic JSON object
/// let json: EZJsonObject = [
///     "name": "Alice",
///     "age": 30,
///     "tags": ["swift", "async"]
/// ]
///
/// let name = json["name"]?.value as? String
/// let firstTag = json["tags"]?[0]?.value as? String
/// ```
///
/// ```swift
/// // Using EZJsonObject as a Codable field instead of `Any`
/// struct Payload: Codable {
///     let meta: EZJsonObject
/// }
///
/// let payload = try JSONDecoder().decode(Payload.self, from: data)
///
/// struct Meta: Codable {
///     let version: Int
///     let flags: [String]
/// }
///
/// let meta: Meta = try payload.meta.convert()
/// ```
public struct EZJsonObject: Codable, @unchecked Sendable {
    /// The underlying JSON-compatible value (e.g. `String`, `NSNumber`, `[Any]`, `[String: Any]`, ...).
    ///
    /// This is intentionally untyped; use `convert(to:)` if you need a strongly-typed `Codable` model.
    public var value: Any
    
    public func encode(to encoder: Encoder) throws {
        switch value{
        case let value as Encodable:
            try value.encode(to: encoder)
        case let value as [String: Any]:
            try DictionaryJsonObject(value: value).encode(to: encoder)
        case let value as [Any]:
            try ArrJsonObjectCodable(value: value).encode(to: encoder)
        default:
            var container = encoder.singleValueContainer()
            try container.encodeNil()
        }
    }
    
    public init(value: Any) {
        self.value = value
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "nil")
        } else if let val = try? container.decode(NSNumber.self) {
            value = val
        } else if let val = try? container.decode(String.self) {
            value = val
        } else if let val = try? container.decode(Bool.self) {
            value = val
        } else if let val = try? container.decode(ArrJsonObjectCodable.self).value {
            value = val
        } else if let val = try? container.decode(DictionaryJsonObject.self).value {
            value = val
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Неизвестный тип данных")
        }
    }
    
    /// Accesses a nested value by string key when `value` is a `[String: Any]` dictionary.
    ///
    /// Returns `nil` if `value` is not a dictionary or the key is missing.
    public subscript(_ key: String) -> EZJsonObject? {
        (value as? [String: Any])?[key].map { .init(value: $0) }
    }
    
    /// Accesses a nested value by index when `value` is an array (`[Any]`).
    ///
    /// Returns `nil` if `value` is not an array or the index is out of bounds.
    public subscript(_ key: Int) -> EZJsonObject? {
        (value as? [Any])?[ezSafe: key].map { .init(value: $0) }
    }
}

extension EZJsonObject: ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: String) {
        self.value = value
    }
}
extension EZJsonObject: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    
    public init(integerLiteral value: Int) {
        self.value = value
    }
}
extension EZJsonObject: ExpressibleByFloatLiteral {
    public typealias FloatLiteralType = Double
    
    public init(floatLiteral value: Double) {
        self.value = value
    }
}
extension EZJsonObject: ExpressibleByBooleanLiteral {
    public typealias BooleanLiteralType = Bool
    
    public init(booleanLiteral value: Bool) {
        self.value = value
    }
}
extension EZJsonObject: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Any
    
    public init(arrayLiteral elements: Any...) {
        self.value = elements
    }
}
extension EZJsonObject: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = Any
    
    public init(dictionaryLiteral elements: (String, Value)...) {
        var result = [String: Any]()
        elements.forEach{ result[$0.0] = $0.1 }
        self.value = result
    }
}

extension EZJsonObject{
    /// Decodes the wrapped JSON value into a strongly-typed `Codable` model.
    ///
    /// This is the recommended way to transform a dynamic `EZJsonObject` field from a `Codable` type
    /// into a concrete model once you know what you expect.
    public func convert<T: Codable>(to type: T.Type = T.self) throws -> T {
        try JSONDecoder().ezDecodeValue(type, from: value)
    }
}

struct DictionaryJsonObject: Codable, @unchecked Sendable {
    var value: [String: Any]
   
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CKey.self)
        try value.forEach {
            try container.encode(EZJsonObject(value: $0.value), forKey: .init($0.key))
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CKey.self)
        var result = [String: Any]()
        container.allKeys.forEach {
            result[$0.stringValue] = (try? EZJsonObject(from: container.superDecoder(forKey: $0)))?.value
        }
        value = result
    }
    
    init(value: [String: Any]) {
        self.value = value
    }
}

extension DictionaryJsonObject: ExpressibleByDictionaryLiteral {
    typealias Key = String
    typealias Value = Any
    
    init(dictionaryLiteral elements: (String, Value)...) {
        var result = [String: Any]()
        elements.forEach { result[$0.0] = $0.1 }
        self.value = result
    }
}

struct ArrJsonObjectCodable: Codable, @unchecked Sendable {
    var value: [Any]
   
    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try value.enumerated().forEach {
            try container.encode(EZJsonObject(value: $0.element))
        }
    }
    
    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var result = [Any]()
        while !container.isAtEnd{
            if let value = (try? EZJsonObject(from: container.superDecoder()))?.value {
                result.append(value)
            }
        }
        value = result
    }
    
    init(value: [Any]) {
        self.value = value
    }
}

extension ArrJsonObjectCodable: ExpressibleByArrayLiteral {
    typealias ArrayLiteralElement = Any
    
    init(arrayLiteral elements: Any...) {
        self.value = elements
    }
}
