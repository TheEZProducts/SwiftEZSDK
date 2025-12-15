//
//  EZHelpersKit_JSONEncoder_encodeValue_Tests.swift
//  EZSDK
//
//  Created by Александр Сенин on 13.12.2025.
//

import XCTest
import Foundation

import EZHelpersKit

final class EZHelpersKit_JSONEncoder_encodeValue_Tests: XCTestCase {
    private struct User: Codable, Equatable {
        let name: String
        let age: Int
        let isAdmin: Bool
        let tags: [String]
        let address: Address
        let nickname: String?

        struct Address: Codable, Equatable {
            let city: String
            let zip: Int
        }
    }

    private struct SnakeKeysModel: Codable, Equatable {
        let userID: Int
        let firstName: String

        enum CodingKeys: String, CodingKey {
            case userID = "user_id"
            case firstName = "first_name"
        }
    }

    func test_encodePrimitiveValues() throws {
        let encoder = JSONEncoder()

        let intAny = try encoder.ezEncodeValue(42)
        XCTAssertEqual(intAny as? Int, 42)

        let boolAny = try encoder.ezEncodeValue(true)
        XCTAssertEqual(boolAny as? Bool, true)

        let doubleAny = try encoder.ezEncodeValue(3.14)
        XCTAssertEqual((doubleAny as? Double)!, 3.14, accuracy: 0.000_001)

        let stringAny = try encoder.ezEncodeValue("hello")
        XCTAssertEqual(stringAny as? String, "hello")
    }

    func test_encodeTopLevelArray() throws {
        let encoder = JSONEncoder()
        let any = try encoder.ezEncodeValue([1, 2, 3, 4, 5])

        guard let array = any as? [Any] else {
            return XCTFail("Expected [Any] as a top-level container")
        }

        XCTAssertEqual(array.compactMap { $0 as? Int }, [1, 2, 3, 4, 5])
    }

    func test_encodeStructToFoundationTree() throws {
        let encoder = JSONEncoder()
        let user = User(
            name: "Alice",
            age: 30,
            isAdmin: true,
            tags: ["ios", "swift"],
            address: .init(city: "Amsterdam", zip: 1011),
            nickname: "ali"
        )

        let any = try encoder.ezEncodeValue(user)
        guard let dict = any as? [String: Any] else {
            return XCTFail("Expected [String: Any] as a top-level container")
        }

        XCTAssertEqual(dict["name"] as? String, "Alice")
        XCTAssertEqual(dict["age"] as? Int, 30)
        XCTAssertEqual(dict["isAdmin"] as? Bool, true)

        let tags = dict["tags"] as? [Any]
        XCTAssertEqual(tags?.compactMap { $0 as? String }, ["ios", "swift"])

        let address = dict["address"] as? [String: Any]
        XCTAssertEqual(address?["city"] as? String, "Amsterdam")
        XCTAssertEqual(address?["zip"] as? Int, 1011)

        XCTAssertEqual(dict["nickname"] as? String, "ali")

        // JSONSerialization-friendly for object/array containers
        XCTAssertTrue(JSONSerialization.isValidJSONObject(dict))
    }

    /// Проверяет поведение при `nil` в Optional: ключ либо отсутствует, либо содержит NSNull.
    func test_encodeOptionalNil() throws {
        let encoder = JSONEncoder()
        let user = User(
            name: "Bob",
            age: 25,
            isAdmin: false,
            tags: [],
            address: .init(city: "Berlin", zip: 10115),
            nickname: nil
        )

        let any = try encoder.ezEncodeValue(user)
        guard let dict = any as? [String: Any] else {
            return XCTFail("Expected [String: Any] as a top-level container")
        }

        let nick = dict["nickname"]
        XCTAssertTrue(nick == nil || nick is NSNull)
    }

    /// Проверяет, что кастомные CodingKeys отражаются в результирующем дереве.
    func test_encodeCustomCodingKeys() throws {
        let encoder = JSONEncoder()
        let model = SnakeKeysModel(userID: 7, firstName: "John")

        let any = try encoder.ezEncodeValue(model)
        guard let dict = any as? [String: Any] else {
            return XCTFail("Expected [String: Any] as a top-level container")
        }

        XCTAssertEqual(dict["user_id"] as? Int, 7)
        XCTAssertEqual(dict["first_name"] as? String, "John")
        XCTAssertNil(dict["userID"])
        XCTAssertNil(dict["firstName"])
    }

    /// Полный round-trip: Codable -> Any -> JSONSerialization.Data -> Codable
    func test_roundTripThroughJSONSerialization() throws {
        let encoder = JSONEncoder()
        let user = User(
            name: "Charlie",
            age: 41,
            isAdmin: false,
            tags: ["backend", "swift"],
            address: .init(city: "Paris", zip: 75001),
            nickname: nil
        )

        let any = try encoder.ezEncodeValue(user)
        guard let object = any as? [String: Any] else {
            return XCTFail("Expected [String: Any] as a top-level container")
        }

        let data = try JSONSerialization.data(withJSONObject: object, options: [])
        let decoded = try JSONDecoder().decode(User.self, from: data)

        XCTAssertEqual(decoded, user)
    }

    /// Измерение производительности кодирования большого массива.
    func test_performanceEncodeLargeArray() {
        let encoder = JSONEncoder()
        let payload = Array(repeating: User(
            name: "Charlie",
            age: 41,
            isAdmin: false,
            tags: ["backend", "swift"],
            address: .init(city: "Paris", zip: 75001),
            nickname: nil
        ), count: 200_000)
        
        self.measure {
            _ = try! encoder.ezEncodeValue(payload)
        }
    }
}

