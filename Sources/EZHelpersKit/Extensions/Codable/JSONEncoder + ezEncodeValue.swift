//
//  JSONEncoder + encodeValue.swift
//  EZSDK
//
//  Created by Александр Сенин on 13.12.2025.
//

import Foundation

public extension JSONEncoder {
    /// Encodes an `Encodable` value into a JSON-compatible `Any` tree.
    ///
    /// Instead of returning `Data`, this helper builds a foundation-style representation
    /// (`[String: Any]`, `[Any]`, `NSNumber`, `String`, etc.).
    ///
    /// This is especially useful together with `EZJsonObject` when you want to round-trip between
    /// strongly-typed `Codable` models and dynamic JSON.
    ///
    /// ### Example
    /// ```swift
    /// struct User: Codable {
    ///     let name: String
    ///     let age: Int
    /// }
    ///
    /// let encoder = JSONEncoder()
    /// let user = User(name: "Alice", age: 30)
    /// let anyJSON = try encoder.ezEncodeValue(user)
    /// // anyJSON is something like ["name": "Alice", "age": 30]
    /// ```
    func ezEncodeValue<T: Encodable>(_ value: T) throws -> Any {
        let encoder = _DictionaryEncoder(userInfo: userInfo)
        try value.encode(to: encoder)
        return encoder.finalize()
    }
}
