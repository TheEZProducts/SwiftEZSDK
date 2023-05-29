//
//  EZObservableKitTest.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import XCTest
@testable import EZObservableKit
#if canImport(EZAssociatedKit)
import EZAssociatedKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif

struct TestWrapper: EZObserverWrapperProtocol, @unchecked Sendable{
    var action: (@escaping () -> ()) -> ()
    
    func use(action: @escaping () -> ()) {
        self.action(action)
    }
}

class Obj{}
class Obj1{
    var value: Int = 0
}

final class EZObservableKitTest: XCTestCase {
    func test_ObservableSet(){
        @EZObservable var value: String = "Hello"
        
        var testBuffer: String = ""
        $value.add { testBuffer = $0.new }
        
        value = "Test"
        XCTAssertEqual(testBuffer, value, "Set Value")
        testBuffer = ""
        
        $value.set(value: "Test", .common)
        XCTAssertEqual(testBuffer, value, "Set Value Common")
        testBuffer = ""
        
        $value.set(value: "Test", .silent)
        XCTAssertNotEqual(testBuffer, value, "Set Value Silent")
        testBuffer = ""
        
        $value.signal()
        XCTAssertEqual(testBuffer, value, "Signal")
        testBuffer = ""
        
        var flag = false
        let wrapper = TestWrapper { flag = true; $0() }
        $value.set(value: "Test", .changeWrapper(wrapper))
        XCTAssertEqual(testBuffer, value, "Set Value ChangeWrapper")
        XCTAssert(flag, "Set Value ChangeWrapper")
        testBuffer = ""
        flag = false
    }
    
    func test_ObservableWrapper(){
        var flag = false
        var testBuffer: String = ""
        
        var wrapper = TestWrapper { flag = true; $0() }
        @EZObservable(defaultWrapper: wrapper) var value: String = "Hello"
        $value.add { testBuffer = $0.new }
        
        value = "Test"
        XCTAssertEqual(testBuffer, value, "Wrapper Worked")
        XCTAssert(flag, "Wrapper Worked")
        testBuffer = ""
        flag = false
        
        $value.set(value: "Test", .silent)
        XCTAssertNotEqual(testBuffer, value, "Wrapper Unworked")
        XCTAssert(!flag, "Wrapper Unworked")
        testBuffer = ""
        flag = false
        
        $value.set(value: "Test", .changeWrapper(nil))
        XCTAssertEqual(testBuffer, value, "Wrapper Unworked")
        XCTAssert(!flag, "Wrapper Unworked")
        testBuffer = ""
        flag = false
        
        let wrapper1 = TestWrapper { flag = true; $0() }
        wrapper.action = {_ in XCTAssert(false, "Wrapper Unworked") }
        $value.set(value: "Test", .changeWrapper(wrapper1))
        XCTAssertEqual(testBuffer, value, "Wrapper Unworked")
        XCTAssert(flag, "Wrapper Unworked")
        testBuffer = ""
        flag = false
    }
    
    func test_ObservableRemoveObserver(){
        var testBuffer: String = ""
        var testBuffer1: String = ""
        var testBuffer2: String = ""
        var testBuffer3: String = ""
        
        @EZObservable var value: String = "Hello"
        let token = $value.add{ testBuffer = $0.new }
        let token1 = $value.add{ testBuffer1 = $0.new }
        let token2 = $value.add{ testBuffer2 = $0.new }
        let token3 = $value.add{ testBuffer3 = $0.new }
        
        value = "Test"
        XCTAssertEqual(testBuffer, value, "Set Value")
        XCTAssertEqual(testBuffer1, value, "Set Value")
        XCTAssertEqual(testBuffer2, value, "Set Value")
        XCTAssertEqual(testBuffer3, value, "Set Value")
        testBuffer = ""
        testBuffer1 = ""
        testBuffer2 = ""
        testBuffer3 = ""
        
        token3.remove()
        token1.remove()
        token2.remove()
        token.remove()
        value = "Test"
        XCTAssertNotEqual(testBuffer, value, "Don't Set Value")
        XCTAssertNotEqual(testBuffer1, value, "Don't Set Value")
        XCTAssertNotEqual(testBuffer2, value, "Don't Set Value")
        XCTAssertNotEqual(testBuffer3, value, "Don't Set Value")
        testBuffer = ""
        testBuffer1 = ""
        testBuffer2 = ""
        testBuffer3 = ""
        
        var anchor: EZObserveAnchorObject? = $value.add{ testBuffer = $0.new }.anchorObject
        value = "\(anchor as Any)"
        XCTAssertEqual(testBuffer, value, "Set Value")
        testBuffer = ""
        
        anchor = nil
        value = "Test"
        XCTAssertNotEqual(testBuffer, value, "Don't Set Value")
        testBuffer = ""
        
#if canImport(EZAssociatedKit)
        var obj: Obj? = .init()
        $value.add{ testBuffer = $0.new }.snapToObject(obj!)
        value = "Test"
        XCTAssertEqual(testBuffer, value, "Set Value")
        testBuffer = ""
        
        obj = nil
        value = "Test"
        XCTAssertNotEqual(testBuffer, value, "Don't Set Value")
        testBuffer = ""
#endif
    }
    
    func test_ObservableCopy(){
        var testBuffer: String = ""
        @EZObservable var value: String = "Hello"
        $value.add{ testBuffer = $0.new }
        
        @EZObservable var value1: String = "Hello1"
        $value1 = $value
        
        value1 = "Test"
        XCTAssertEqual(testBuffer, value, "Set Copy Value")
        XCTAssertEqual(testBuffer, value1, "Set Copy Value")
        value1 = ""
        
        var testBuffer1: String = ""
        $value1.add{ testBuffer1 = $0.new }
        value = "Test"
        XCTAssertEqual(testBuffer, value, "Set Copy Value")
        XCTAssertEqual(testBuffer1, value1, "Set Copy Value")
        XCTAssertEqual(testBuffer1, testBuffer, "Set Copy Value")
    }
    
    func test_ObservableHandler(){
        var testBuffer: String = ""
        @EZObservable var value: Int = 0
        @EZObservable var value1: String = "Hello"
        $value1 = $value.handler{"\($0)"}
        $value1.add{ testBuffer = $0.new }
        
        value = 10
        XCTAssertEqual(testBuffer, "\(value)", "Set Child Value")
        testBuffer = ""
        
        $value1.breakParentDependansy()
        value = 10
        XCTAssertNotEqual(testBuffer, "\(value)", "Don't Set Child Value")
        testBuffer = ""
    }
    
    func test_ObservableSwitcher(){
        var testBuffer: String = ""
        @EZObservable var value: Int = 0
        @EZObservable var value1: String = ""
        
        if let valueL = $value.switcher("Hello", "World", "Test"){ $value1 = valueL }
        $value1.add{ testBuffer = $0.new }.use()
        XCTAssertEqual(testBuffer, "Hello", "Set Int Switcher Value")
        value = 1
        XCTAssertEqual(testBuffer, "World", "Set Int Switcher Value")
        value = 2
        XCTAssertEqual(testBuffer, "Test", "Set Int Switcher Value")
        value = 3
        XCTAssertEqual(testBuffer, "Hello", "Set Int Switcher Value")
        testBuffer = ""
        
        @EZObservable var value2: Bool = true
        $value1 = $value2.switcher("Hello", "World")
        $value1.add{ testBuffer = $0.new }.use()
        XCTAssertEqual(testBuffer, "Hello", "Set Bool Switcher Value")
        value2 = false
        XCTAssertEqual(testBuffer, "World", "Set Bool Switcher Value")
        testBuffer = ""
        
        @EZObservable var value3: String = "0"
        if let valueL = $value3.switcher(defaultValue: "Hello", ["0": "Hello", "1": "World", "2": "Test"]){ $value1 = valueL }
        $value1.add{ testBuffer = $0.new }.use()
        XCTAssertEqual(testBuffer, "Hello", "Set Int Switcher Value")
        value3 = "1"
        XCTAssertEqual(testBuffer, "World", "Set Int Switcher Value")
        value3 = "2"
        XCTAssertEqual(testBuffer, "Test", "Set Int Switcher Value")
        value3 = "3"
        XCTAssertEqual(testBuffer, "Hello", "Set Int Switcher Value")
        testBuffer = ""
    }
    
    func test_ObservableToken(){
        var testBuffer: String = ""
        @EZObservable var value: String = "Hello"
        
        $value.add{testBuffer = $0.new}.use()
        XCTAssertEqual(testBuffer, "\(value)", "Set Value")
        testBuffer = ""
    }
    
#if canImport(SwiftUI)
    @available(tvOS 13.0, *)
    @available(watchOS 6.0, *)
    @available(iOS 13.0, *)
    @available(macOS 10.15, *)
    func test_ObservableBinding(){
        let testBuffer: Int = 10
        @EZObservable var value: Obj1 = .init()
        $value.add{ XCTAssertEqual(testBuffer, $0.new.value, "Set Value") }
        let binding = $value.binding(keyPath: \.value)
        binding.wrappedValue = testBuffer
        
        XCTAssertEqual(testBuffer, binding.wrappedValue, "Get Value")
    }
#endif
    
    func test_ObservableEZBinding(){
        let testBuffer: Int = 10
        @EZObservable var value: Obj1 = .init()
        $value.add{ XCTAssertEqual(testBuffer, $0.new.value, "Set Value") }
        let binding: EZBinding = $value.binding(keyPath: \.value)
        binding.wrappedValue = testBuffer
        
        XCTAssertEqual(testBuffer, binding.wrappedValue, "Get Value")
    }
    
    @EZObservable var value: String = "Hello"
    
    @available(iOS 13.0.0, *)
    @available(tvOS 13.0.0, *)
    @available(watchOS 6.0.0, *)
    func test_ObservableThreadSafety() async{
        print("start")
        let t1 = Task{
            print("t1", "start")
            for i in 0...1000{
                value = value + "\(i)"
                $value.add{_ in}
                $value.removeAll()
            }
            print("t1", "end")
            return value
        }
        let t2 = Task{
            print("t2", "start")
            for i in 0...1000{
                value = value + "\(i)"
                $value.add{_ in}
                $value.removeAll()
            }
            print("t2", "end")
            return value
        }
        let t3 = Task{
            print("t3", "start")
            for i in 0...1000{
                value = value + "\(i)"
                $value.add{_ in}
                $value.removeAll()
            }
            print("t3", "end")
            return value
        }
        _ = await (t1.value, t2.value, t3.value)
        print("end")
    }

}
