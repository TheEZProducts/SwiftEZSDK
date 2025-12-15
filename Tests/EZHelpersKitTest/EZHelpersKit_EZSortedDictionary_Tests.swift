//
//  EZHelpersKit_EZSortedDictionary_Tests.swift
//  EZSDK
//
//  Created by Александр Сенин on 13.12.2025.
//

import XCTest
import Foundation

import EZHelpersKit

final class EZHelpersKit_EZSortedDictionary_Tests: XCTestCase {
    func test_makeDictionary() throws {
        let testDictionary: EZSortedDictionary = [2: "2", 1: "1", 3: "3", 4: "4", 0: "0"]
        checkSorted(testDictionary)
    }
    
    func test_appendDictionary() throws {
        var testDictionary = EZSortedDictionary<Int, String>()
        testDictionary[0] = "0"
        testDictionary[3] = "3"
        testDictionary[2] = "2"
        testDictionary[4] = "4"
        testDictionary[1] = "1"
        
        checkSorted(testDictionary)
    }
    
    func test_removeDictionary() throws {
        var dict: EZSortedDictionary<Int, String> = [0: "zero", 1: "one", 2: "two", 3: "three", 4: "four"]
        // remove by key
        dict[2] = nil
        XCTAssertNil(dict[2])
        XCTAssertEqual(dict.count, 4)
        // remove by index
        let removed = dict.remove(at: 0)
        XCTAssertEqual(removed.key, 0)
        XCTAssertEqual(removed.value, "zero")
        XCTAssertEqual(dict.count, 3)
        // removeFirst and removeLast
        let firstRemoved = dict.removeFirst()
        XCTAssertEqual(firstRemoved.key, 1)
        let lastRemoved = dict.removeLast()
        XCTAssertEqual(lastRemoved.key, 4)
        // popFirst and popLast on empty
        dict.removeAll()
        XCTAssertTrue(dict.isEmpty)
        XCTAssertNil(dict.popFirst())
        XCTAssertNil(dict.popLast())
        // removeFirst(n) and removeLast(n)
        dict = [1: "one", 2: "two", 3: "three", 4: "four", 5: "five"]
        dict.removeFirst(2)
        XCTAssertEqual(dict.keys, [3,4,5])
        dict.removeLast(1)
        XCTAssertEqual(dict.keys, [3,4])
        // dropFirst and dropLast non-mutating
        let droppedFirst = dict.dropFirst(1)
        XCTAssertEqual(droppedFirst.keys, [4])
        let droppedLast = dict.dropLast(1)
        XCTAssertEqual(droppedLast.keys, [3])
    }

    func test_keysValuesFirstLast() {
        let dict: EZSortedDictionary = [10: "ten", 5: "five", 20: "twenty"]
        XCTAssertEqual(dict.keys, [5,10,20])
        XCTAssertEqual(dict.values, ["five","ten","twenty"])
        XCTAssertEqual(dict.first?.key, 5)
        XCTAssertEqual(dict.last?.key, 20)
    }

    func test_unionIntersectionOperators() {
        let a: EZSortedDictionary = [1:"a", 2:"b", 3:"c"]
        let b: EZSortedDictionary = [2:"bb", 4:"d"]
        let u = a + b
        XCTAssertEqual(u.keys, [1,2,3,4])
        XCTAssertEqual(u[2], "bb")
        var c = a
        c += b
        XCTAssertEqual(c, u)
        let i = a.intersection(b)
        XCTAssertEqual(i.keys, [2])
        let sub = u - a
        XCTAssertEqual(sub.keys, [4])
        var d = u
        d -= a
        XCTAssertEqual(d.keys, [4])
    }

    func test_codableRoundTrip() throws {
        let original: EZSortedDictionary = [3:"three",1:"one",2:"two"]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(EZSortedDictionary<Int,String>.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func test_safePositionSubscript() {
        var dict: EZSortedDictionary = [1:"one",2:"two",3:"three"]
        XCTAssertEqual(dict[safePosition: 1], "two")
        XCTAssertNil(dict[safePosition: 10])
        dict[safePosition: 1] = "TWO"
        XCTAssertEqual(dict[2], "TWO")
        dict[safePosition: 1] = nil
        XCTAssertEqual(dict.keys, [1,3])
    }
    
    /// Проверяет, что при декодировании массива пар в произвольном порядке словарь сортируется по ключу.
    func test_codableUnsortedJSON() throws {
        let json = """
        [
            {"key": 3, "value": "three"},
            {"key": 1, "value": "one"},
            {"key": 2, "value": "two"}
        ]
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(EZSortedDictionary<Int, String>.self, from: data)
        XCTAssertEqual(decoded.keys, [1,2,3])
        XCTAssertEqual(decoded.values, ["one","two","three"])
    }

    /// Измерение производительности вставки большого количества элементов.
    func test_performanceInsertion() {
        self.measure {
            var dict = EZSortedDictionary<Int, Int>()
            for i in 0..<200_000 {
                dict[i] = i
            }
        }
    }
    
    func test_performanceInsertion1() {
        self.measure {
            var dict = Dictionary<Int, Int>()
            for i in 0..<200_000 {
                dict[i] = i
            }
        }
    }

    /// Измерение производительности поиска по ключу в большом словаре.
    func test_performanceLookup() {
        var dict = EZSortedDictionary<Int, Int>()
        for i in 0..<200_000 {
            dict[i] = i
        }
        self.measure {
            for i in 0..<200_000 {
                _ = dict[i]!
            }
        }
    }
    
    func test_performanceLookup1() {
        var dict = Dictionary<Int, Int>()
        for i in 0..<200_000 {
            dict[i] = i
        }
        self.measure {
            for i in 0..<200_000 {
                _ = dict[i]!
            }
        }
    }
    
    func test_rangeMethod() {
        let dict: EZSortedDictionary = [1:"one",2:"two",3:"three",4:"four",5:"five"]
        let rangePairs = dict.range(2, 4)
        XCTAssertEqual(rangePairs.map { $0.key }, [2,3,4])
        XCTAssertEqual(rangePairs.map { $0.value }, ["two","three","four"])
    }

   

    func test_unlabeledRangeSubscriptIteration() {
        let dict: EZSortedDictionary = [1:"one",2:"two",3:"three",4:"four",5:"five"]
        let slice = dict[2...4]  // ArraySlice<Pair>
        XCTAssertEqual(slice.map { $0.key }, [2,3,4])
        var iterKeys: [Int] = []
        for pair in dict[2...4] {
            iterKeys.append(pair.key)
        }
        XCTAssertEqual(iterKeys, [2,3,4])
    }

    
    func checkSorted<Value>(_ testDictionary: EZSortedDictionary<Int, Value>) {
        for (i, pare) in testDictionary.elements.enumerated() {
            XCTAssertEqual(i, pare.key, "Value not equal")
        }
    }
}



