//
//  EZThreadSafetyTest.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import XCTest
import EZAsyncKit

final class EZAsyncKitTest: XCTestCase, @unchecked Sendable {
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func test_ThreadSafety_Async() async{
        @EZThreadSafety var testValue: String = "Hello"
        
        print("test_ThreadSafety_Async start")
        let t1 = Task.detached {[testValue = $testValue, weak self] in
            print("t1", "start")
            for i in 0...100000{
                await self?.addTestValueAsync(value: testValue, i: i)
            }
            print("t1", "end")
            return testValue
        }
        let t2 = Task.detached {[testValue = $testValue, weak self] in
            print("t2", "start")
            for i in 0...100000{
                await self?.addTestValueAsync(value: testValue, i: i)
            }
            print("t2", "end")
            return testValue
        }
        let t3 = Task.detached {[testValue = $testValue, weak self] in
            print("t3", "start")
            for i in 0...100000{
                await self?.addTestValueAsync(value: testValue, i: i)
            }
            print("t3", "end")
            return testValue
        }
        _ = await (t1.value, t2.value, t3.value)
        print("test_ThreadSafety_Async end")
    }
    
    private func addTestValueAsync(value: EZThreadSafety<String>, i: Int) async {
        await value.update{ $0 + "\(i)" }
    }
    
    @available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
    func test_ThreadSafety_Sync() async{
        @EZThreadSafety var testValue: String = "Hello"
        
        print("test_ThreadSafety_Sync start")
        let t1 = Task.detached {[testValue = $testValue, weak self] in
            print("t1", "start")
            for i in 0...100000{
                self?.addTestValueSync(value: testValue, i: i)
            }
            print("t1", "end")
            return testValue
        }
        let t2 = Task.detached {[testValue = $testValue, weak self] in
            print("t2", "start")
            for i in 0...100000{
                self?.addTestValueSync(value: testValue, i: i)
            }
            print("t2", "end")
            return testValue
        }
        let t3 = Task.detached {[testValue = $testValue, weak self] in
            print("t3", "start")
            for i in 0...100000{
                self?.addTestValueSync(value: testValue, i: i)
            }
            print("t3", "end")
            return testValue
        }
        _ = await (t1.value, t2.value, t3.value)
        print("test_ThreadSafety_Sync end")
    }

    private func addTestValueSync(value: EZThreadSafety<String>, i: Int) {
        value.update{ $0 + "\(i)" }
    }
}
