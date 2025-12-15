//
//  EZHelpersKit_DictionaryEncoderDecoder_Tests.swift
//  EZSDK
//
//  Created by Александр Сенин on 13.12.2025.
//

import XCTest
import Foundation

import EZHelpersKit

final class EZHelpersKit_DictionaryEncoderDecoder_Tests: XCTestCase {
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

    func test_roundTrip_struct() throws {
        let original = User(
            name: "Alice",
            age: 30,
            isAdmin: true,
            tags: ["ios", "swift"],
            address: .init(city: "Amsterdam", zip: 1011),
            nickname: "ali"
        )

        let any = try JSONEncoder().ezEncodeValue(original)
        let decoded: User = try JSONDecoder().ezDecodeValue(User.self, from: any)

        XCTAssertEqual(decoded, original)

        // JSONSerialization-friendly for object/array containers
        XCTAssertTrue(JSONSerialization.isValidJSONObject(any))
    }

    func test_roundTrip_topLevelArray() throws {
        let payload = Array(0..<10_000)
        let any = try JSONEncoder().ezEncodeValue(payload)
        let decoded: [Int] = try JSONDecoder().ezDecodeValue([Int].self, from: any)
        XCTAssertEqual(decoded, payload)
    }

    func test_encodeOptionalNil_keyIsAbsentOrNull() throws {
        let original = User(
            name: "Bob",
            age: 25,
            isAdmin: false,
            tags: [],
            address: .init(city: "Berlin", zip: 10115),
            nickname: nil
        )

        let any = try JSONEncoder().ezEncodeValue(original)
        guard let dict = any as? [String: Any] else {
            return XCTFail("Expected [String: Any] as a top-level container")
        }

        let nick = dict["nickname"]
        XCTAssertTrue(nick == nil || nick is NSNull)

        // decode also works
        let decoded: User = try JSONDecoder().ezDecodeValue(User.self, from: any)
        XCTAssertEqual(decoded, original)
    }

    func test_decodeError_containsCodingPath_keysAndIndex() {
        struct Wrapper: Decodable {
            let a: [Inner]
            struct Inner: Decodable {
                let b: Int
            }
        }

        let any: Any = [
            "a": [
                ["b": "notInt"]
            ]
        ]

        do {
            _ = try JSONDecoder().ezDecodeValue(Wrapper.self, from: any)
            XCTFail("Expected decode to throw")
        } catch let DecodingError.typeMismatch(_, context) {
            // Expect path: a -> 0 -> b
            let path = context.codingPath.map { $0.stringValue }
            XCTAssertEqual(path, ["a", "0", "b"])
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_superEncoder_superDecoder_roundTripInheritance() throws {
        class Base: Codable, Equatable {
            static func == (lhs: Base, rhs: Base) -> Bool { lhs.a == rhs.a }

            var a: Int
            init(a: Int) { self.a = a }

            enum CodingKeys: String, CodingKey { case a }

            required init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                a = try c.decode(Int.self, forKey: .a)
            }

            func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encode(a, forKey: .a)
            }
        }

        class Child: Base {
            var b: Int

            init(a: Int, b: Int) {
                self.b = b
                super.init(a: a)
            }

            enum CodingKeys: String, CodingKey { case b }

            required init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                b = try c.decode(Int.self, forKey: .b)
                try super.init(from: c.superDecoder())
            }

            override func encode(to encoder: Encoder) throws {
                var c = encoder.container(keyedBy: CodingKeys.self)
                try c.encode(b, forKey: .b)
                try super.encode(to: c.superEncoder())
            }

            static func == (lhs: Child, rhs: Child) -> Bool {
                lhs.a == rhs.a && lhs.b == rhs.b
            }
        }

        let original = Child(a: 1, b: 2)
        let any = try JSONEncoder().ezEncodeValue(original)
        let decoded: Child = try JSONDecoder().ezDecodeValue(Child.self, from: any)

        XCTAssertEqual(decoded, original)

        // Also assert the "super" slot exists in the produced tree.
        guard let dict = any as? [String: Any] else {
            return XCTFail("Expected [String: Any] as a top-level container")
        }
        XCTAssertNotNil(dict["super"])
    }

    func test_performance_decodeLargeArray() {
        let payload = Array(repeating: User(
            name: "Charlie",
            age: 41,
            isAdmin: false,
            tags: ["backend", "swift"],
            address: .init(city: "Paris", zip: 75001),
            nickname: nil
        ), count: 200_000)
        let any = try! JSONEncoder().ezEncodeValue(payload)

        self.measure {
            _ = try? JSONDecoder().ezDecodeValue([User].self, from: any)
        }
    }
}
