//
//  Untitled.swift
//  EZSDK
//
//  Created by Александр Сенин on 13.12.2025.
//

import Foundation

public extension JSONDecoder {
    /// Decodes a `Decodable` value from a JSON-compatible `Any` tree.
    ///
    /// This is the inverse of `JSONEncoder.ezEncodeValue(_:)`: instead of starting from `Data`,
    /// you pass a foundation-style representation (`[String: Any]`, `[Any]`, `NSNumber`, `String`, etc.)
    /// and get back a strongly-typed model.
    ///
    /// Especially useful together with `EZJsonObject` when you receive dynamic JSON but later want to
    /// interpret it as a concrete `Codable` type.
    ///
    /// ### Example
    /// ```swift
    /// struct User: Codable {
    ///     let name: String
    ///     let age: Int
    /// }
    ///
    /// let anyJSON: Any = ["name": "Alice", "age": 30]
    /// let decoder = JSONDecoder()
    /// let user = try decoder.ezDecodeValue(User.self, from: anyJSON)
    /// ```
    func ezDecodeValue<T: Decodable>(_ type: T.Type, from anyJSON: Any) throws -> T {
        let decoder = _DictionaryDecoder(value: anyJSON, userInfo: userInfo)
        return try T(from: decoder)
    }
}
