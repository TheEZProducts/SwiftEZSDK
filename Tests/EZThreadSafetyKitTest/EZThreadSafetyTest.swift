//
//  EZThreadSafetyTest.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import XCTest
import EZThreadSafetyKit

final class EZThreadSafetyTest: XCTestCase {
    @EZThreadSafety var testValue: String = "Hello"
    
    @available(iOS 13.0.0, *)
    @available(tvOS 13.0.0, *)
    @available(watchOS 6.0.0, *)
    func test_ThreadSafety() async{
        print("start")
        let t1 = Task{
            print("t1", "start")
            for i in 0...1000{
                testValue = testValue + "\(i)"
            }
            print("t1", "end")
            return testValue
        }
        let t2 = Task{
            print("t2", "start")
            for i in 0...1000{
                testValue = testValue + "\(i)"
            }
            print("t2", "end")
            return testValue
        }
        let t3 = Task{
            print("t3", "start")
            for i in 0...1000{
                testValue = testValue + "\(i)"
            }
            print("t3", "end")
            return testValue
        }
        _ = await (t1.value, t2.value, t3.value)
        print("end")
    }

}
