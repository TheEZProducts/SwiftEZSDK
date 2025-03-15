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

final class EZObservableKitTest: XCTestCase, @unchecked Sendable {
    func test_ObservableSet(){
        @EZObservable var value: String = "Hello"
        
        var testBuffer: String = ""
        $value.addWithIsolation { testBuffer = $0.new }
        
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
        $value.addWithIsolation { testBuffer = $0.new }
        
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
        let token = $value.addWithIsolation { testBuffer = $0.new }
        let token1 = $value.addWithIsolation { testBuffer1 = $0.new }
        let token2 = $value.addWithIsolation { testBuffer2 = $0.new }
        let token3 = $value.addWithIsolation { testBuffer3 = $0.new }
        
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
        
        var anchor: EZObserveAnchorObject? = $value.addWithIsolation { testBuffer = $0.new }.anchorObject
        value = "\(anchor as Any)"
        XCTAssertEqual(testBuffer, value, "Set Value")
        testBuffer = ""
        
        anchor = nil
        value = "Test"
        XCTAssertNotEqual(testBuffer, value, "Don't Set Value")
        testBuffer = ""
        
#if canImport(EZAssociatedKit)
        var obj: Obj? = .init()
        $value.addWithIsolation { testBuffer = $0.new }.snapToObject(obj!)
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
        $value.addWithIsolation { testBuffer = $0.new }
        
        @EZObservable var value1: String = "Hello1"
        $value1 = $value
        
        value1 = "Test"
        XCTAssertEqual(testBuffer, value, "Set Copy Value")
        XCTAssertEqual(testBuffer, value1, "Set Copy Value")
        value1 = ""
        
        var testBuffer1: String = ""
        $value1.addWithIsolation { testBuffer1 = $0.new }
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
        $value1.addWithIsolation { testBuffer = $0.new }
        
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
        $value1.addWithIsolation { testBuffer = $0.new }.use()
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
        $value1.addWithIsolation { testBuffer = $0.new }.use()
        XCTAssertEqual(testBuffer, "Hello", "Set Bool Switcher Value")
        value2 = false
        XCTAssertEqual(testBuffer, "World", "Set Bool Switcher Value")
        testBuffer = ""
        
        @EZObservable var value3: String = "0"
        if let valueL = $value3.switcher(defaultValue: "Hello", ["0": "Hello", "1": "World", "2": "Test"]){ $value1 = valueL }
        $value1.addWithIsolation { testBuffer = $0.new }.use()
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
        
        $value.addWithIsolation {testBuffer = $0.new}.use()
        XCTAssertEqual(testBuffer, "\(value)", "Set Value")
        testBuffer = ""
    }
    
#if canImport(SwiftUI)
    @available(tvOS 13.0, *)
    @available(watchOS 6.0, *)
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
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

    
    typealias Seter = TestKeyStrider1
    @MainActor
    func test_my(){
//        let view = UIView()
//        TestKeyStrider1(view)
//            .frame{$0
//                .size(.init(width: 10, height: 10))
//                .origin{ $0.x(10).y(10) }
//            }
//            .layer{$0
//                .shadowOffset(.init(width: 10, height: 10))
//                .masksToBounds(true)
//            }
//            .backgroundColor(.white)
//            .isHidden(true)
//
        
//        TestKeyStrider(view)
//            .backgroundColor(.white)
//            .frame.size.width(100)
//            .frame.size.height(100)
//            .center(.init(x: 10, y: 10))
//            .alpha(0.5)
//            .layer.masksToBounds(true)
//            .superview.frame.size.width(100)
            
        
        
        
        
            
//        let test = TestClass()
//        let key = \TestClass.value1?.value1?.value
//        TestKeyStrider1(test)
//            .value3{$0
//                .self(20)
//            }
            
//            .value(10)
//            .value1{$0
//
//                .value(10)
////                .value(.some(nil))
//                .value1(TestClass1())
//            }
//            .value1.value1.value(10)
//            .value2("World")
//        test[keyPath: \.value1.value] = 10
        
//        TestKeyStrider1(test)
//            .value1{$0
//                .value(100)
//            }
//            .value(100)
//            .value2("World")
            
//            .value1[dynamicMember: \.?.value]
         
//        let key: KeyPath<TestKeyStrider<TestClass, TestClass>, TestKeyStrider<TestClass, Int>> = \.value
//        let key: KeyPath<TestClass, TestClass1?> = \.value1
//        let key1: KeyPath<TestClass1, Int> = \.value
        
//        let key2 = key.appending(path: key1)
//        let key2: KeyPath<TestClass, Int?> = \.value1?.value
        
//        let key = \TestClass.value1.value
        
        
//        TestStrider(test)
//            .value1.value(10)
//            .value(100)
//            .value2("world")
//        Seter(test)
//            .value(0)
//            .value1(nil)
////            .value1(.init())
//            .value1.value(100)
//            .value2("world")
    }
    
    class Dier{
        var int: Int = .random(in: 0...100000)
        init() { print("i live \(int)", Unmanaged.passRetained(self).toOpaque()) }
        deinit { print("i die \(int)", Unmanaged.passRetained(self).toOpaque()) }
    }
    
    var tl: ThreadLocal<Dier>? = ThreadLocal<Dier>(value: .init())
    
//    func testThr() async{
//        print("start")
//        
//        
//        
//        print(tl?.inner.value.int)
//        DispatchQueue.global(qos: .utility).async {
//            print(self.tl?.inner.value.int)
//        }
//        sleep(1)
//        print("1")
////        await Task{
////            print(tl?.inner.value.int)
////        }.value
//        tl = nil
//        sleep(1)
//        print("2")
//        
//        print("end")
//        
//    }
}

class TestClass{
    var value: Int = 10
    let value1: TestClass1? = TestClass1()
    var value2: String = "Hello"
    var value3: Int? = 10
}

class TestClass1{
    var value: Int = 1100
    var value1: TestClass1?
}

protocol SeterProtocol {}

@dynamicMemberLookup
struct Seter<MainSeter, Subject>: SeterProtocol{
    private var getMain: MainSeter
    private var setAction: (Subject) -> ()
    private var getAction: () -> (Subject?)
    
    init(_ subject: Subject) where Subject: AnyObject, MainSeter == Void {
        setAction = {_ in }
        getAction = { subject }
        getMain = ()
    }
    
    init(_ subject: UnsafeMutablePointer<Subject>) where MainSeter == Void {
        setAction = { subject.pointee = $0 }
        getAction = { subject.pointee }
        getMain = ()
    }
    
    @_disfavoredOverload
    subscript<V>(dynamicMember key: WritableKeyPath<Subject, V>) -> Seter<Self, V> where MainSeter == Void{
        .init(getMain: self) { value in
            guard var old = getAction() else { return }
            old[keyPath: key] = value
            setAction(old)
        } getAction: { getAction()?[keyPath: key] }
    }
    
    @_disfavoredOverload
    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Subject, V>) -> Seter<Self, V> where MainSeter == Void{
        .init(getMain: self) { getAction()?[keyPath: key] = $0} getAction: { getAction()?[keyPath: key] }
    }
    
    @_disfavoredOverload
    subscript<V>(dynamicMember key: WritableKeyPath<Subject, V>) -> Seter<MainSeter, V>{
        .init(getMain: getMain) { value in
            guard var old = getAction() else { return }
            old[keyPath: key] = value
            setAction(old)
        } getAction: {
            getAction()?[keyPath: key]
        }
    }
    
    @_disfavoredOverload
    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Subject, V>) -> Seter<MainSeter, V>{
        .init(getMain: getMain) { getAction()?[keyPath: key] = $0} getAction: { getAction()?[keyPath: key] }
    }
    //
    subscript<V>(dynamicMember key: WritableKeyPath<Subject, Optional<V>>) -> Seter<Self, V> where MainSeter == Void{
        .init(getMain: self) { value in
            guard var old = getAction() else { return }
            old[keyPath: key] = value
            setAction(old)
        } getAction: { getAction()?[keyPath: key] }
    }
    
    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Subject, Optional<V>>) -> Seter<Self, V> where MainSeter == Void{
        .init(getMain: self) { getAction()?[keyPath: key] = $0} getAction: { getAction()?[keyPath: key] }
    }

    subscript<V>(dynamicMember key: WritableKeyPath<Subject, Optional<V>>) -> Seter<MainSeter, V>{
        .init(getMain: getMain) { value in
            guard var old = getAction() else { return }
            old[keyPath: key] = value
            setAction(old)
        } getAction: {
            getAction()?[keyPath: key]
        }
    }

    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Subject, Optional<V>>) -> Seter<MainSeter, V>{
        .init(getMain: getMain) { getAction()?[keyPath: key] = $0} getAction: { getAction()?[keyPath: key] }
    }
    
    init(
        getMain: MainSeter,
        setAction: @escaping (Subject) -> (),
        getAction: @escaping () -> (Subject?)
    ){
        self.getMain = getMain
        self.setAction = setAction
        self.getAction = getAction
    }
    
    @discardableResult
    func callAsFunction(_ value: Subject) -> Self where MainSeter == Void {
        setAction(value)
        return self
    }
    
    @discardableResult
    func callAsFunction(_ value: Subject) -> MainSeter {
        setAction(value)
        return getMain
    }
}

postfix operator |?
extension Seter {
    func unwrapp<New>() -> Seter<MainSeter, New> where Subject == Optional<New>{
        .init(getMain: getMain) { value in
            guard let old = getAction() else { return }
            setAction(old)
        } getAction: {
            getAction() ?? nil
        }
    }
}

protocol OptionalWrapper<Wrapped>: ExpressibleByNilLiteral {
    associatedtype Wrapped
}


extension Optional: OptionalWrapper {
    typealias Wrapped = Wrapped
}


extension Seter where Subject: OptionalWrapper{
    var unw: Seter<MainSeter, Subject.Wrapped>{
        .init(getMain: getMain) { value in
            guard let old = getAction() else { return }
            setAction(old)
        } getAction: {
            (getAction() as? Subject.Wrapped) ?? .init(nilLiteral: ())
        }
    }
}

protocol Oh {
    func oh()
}

class TestC<T> {
    func oh() {
        print("bad")
    }
}

extension TestC where T == Int {
    func oh() {
        print("Int")
    }
}

extension TestC where T == String {
    func oh() {
        print("String")
    }
}

@inline(__always)
func test<V>(v: V.Type = V.self) {
    TestC<V>().oh()
}

//MARK: - V2
protocol ContainerProto<Subject>{
    associatedtype Subject
    
    var setAction: (Subject) -> () { get }
    var getAction: () -> (Subject) { get }
}

struct Container<Subject>: ContainerProto{
    var setAction: (Subject) -> ()
    var getAction: () -> (Subject)
    
    var value: Subject {
        nonmutating set(new){ setAction(new) }
        get{ getAction() }
    }
}

@dynamicMemberLookup
struct TestKeyStrider<Subject, Value>{
    private var c: Container<Subject>
    private var key: KeyPath<Subject, Value>
    
    init(_ subject: Subject) where Subject: AnyObject, Subject == Value{
        self.c = .init(setAction: {_ in }, getAction: { subject })
        self.key = \.self
    }
    
    init(_ subject: UnsafeMutablePointer<Subject>) where Subject == Value{
        self.c = .init(setAction: {subject.pointee = $0}, getAction: {subject.pointee})
        self.key = \.self
    }
    
    init(_ c: Container<Subject>, key: KeyPath<Subject, Value>){
        self.c = c
        self.key = key
    }
    
    subscript<V>(dynamicMember key: KeyPath<Value, V>) -> TestKeyStrider<Subject, V>{
        .init(c, key: self.key.appending(path: key))
    }
    
    @discardableResult
    func callAsFunction(_ value: Value) -> TestKeyStrider<Subject, Subject> {
        if let key = key as? WritableKeyPath<Subject, Value>{
            c.value[keyPath: key] = value
        }
        return .init(c, key: \.self)
    }
    
//    @discardableResult
//    func callAsFunction(_ value: (TestKeyStrider<Value, Value>) -> ()) -> TestKeyStrider<Subject, Subject> {
//        if let key = key as? WritableKeyPath<Subject, Value>{
//            value(.init(&c.value[keyPath: key]))
//        }
//        return .init(c, key: \.self)
//    }
}

@dynamicMemberLookup
struct TestKeyStrider1<Subject, Value, DValue>{
    private var c: Container<Subject>
    private var key: KeyPath<Subject, Value>
    private var dKey: KeyPath<Subject, DValue>
    
    init(_ subject: Subject) where Subject: AnyObject, Subject == Value, Subject == DValue{
        self.c = .init(setAction: {_ in }, getAction: { subject })
        self.dKey = \.self
        self.key = self.dKey
        
    }
    
    init(_ subject: UnsafeMutablePointer<Subject>) where Subject == Value, Subject == DValue{
        self.c = .init(setAction: {subject.pointee = $0}, getAction: {subject.pointee})
        self.dKey = \.self
        self.key = self.dKey
    }
    
    init(_ c: Container<Subject>, key: KeyPath<Subject, Value>, dKey: KeyPath<Subject, DValue>){
        self.c = c
        self.key = key
        self.dKey = dKey
    }
    
//    @_disfavoredOverload
    subscript<V>(dynamicMember key: KeyPath<Value, V>) -> TestKeyStrider1<Subject, V, DValue>{
        .init(c, key: self.key.appending(path: key), dKey: dKey)
    }
    
    @discardableResult
    func callAsFunction(_ value: Value) -> TestKeyStrider1<Subject, DValue, DValue> {
        if let key = key as? WritableKeyPath<Subject, Value>{
            c.value[keyPath: key] = value
        }
        return .init(c, key: dKey, dKey: dKey)
    }
    
    @discardableResult
    func callAsFunction(_ value: (TestKeyStrider1<Subject, Value, Value>) -> ()) -> TestKeyStrider1<Subject, DValue, DValue> {
        value(.init(c, key: key, dKey: key))
        return .init(c, key: dKey, dKey: dKey)
    }
}

extension TestKeyStrider1{
//    subscript<WV>(
//        dynamicMember key: KeyPath<Value, Optional<WV>>
//    ) -> TestKeyStrider1<Subject, OptionalWrapper1<WV>, DValue> {
//        return .init(c, key: self.key.appending(path: key).appending(path: \.wrapper), dKey: dKey)
//    }
}


//@dynamicMemberLookup
protocol TestProtocolfsdf{
    associatedtype Wrapped

    @_disfavoredOverload
    subscript<V>(dynamicMember key: KeyPath<Wrapped, V>) -> V? { get }

    @_disfavoredOverload
    subscript<V>(dynamicMember key: WritableKeyPath<Wrapped, V>) -> V? { get set }

    @_disfavoredOverload
    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Wrapped, V>) -> V? { get nonmutating set }

    subscript<V>(dynamicMember key: KeyPath<Wrapped, Optional<V>>) -> V? { get }
    subscript<V>(dynamicMember key: WritableKeyPath<Wrapped, Optional<V>>) -> V? { get set }
    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Wrapped, Optional<V>>) -> V? { get nonmutating set }
}

//@dynamicMemberLookup
//struct OptionalWrapper1<Wrapped>{
//    var wrappedO: Optional<Wrapped>
//    init(wrappedO: Optional<Wrapped>) {
//        self.wrappedO = wrappedO
//    }
//
//    subscript<V>(dynamicMember key: KeyPath<Wrapped, Optional<V>>) -> V? { wrappedO?[keyPath: key] }
//
//    subscript<V>(dynamicMember key: WritableKeyPath<Wrapped, Optional<V>>) -> V? {
//        set(value){ wrappedO?[keyPath: key] = value }
//        get{ wrappedO?[keyPath: key] }
//    }
//
//    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Wrapped, Optional<V>>) -> V? {
//        nonmutating set(value) { wrappedO?[keyPath: key] = value }
//        get { wrappedO?[keyPath: key] }
//    }
//
//    @_disfavoredOverload
//    subscript<V>(dynamicMember key: KeyPath<Wrapped, V>) -> V? { wrappedO?[keyPath: key] }
//
//    @_disfavoredOverload
//    subscript<V>(dynamicMember key: WritableKeyPath<Wrapped, V>) -> V? {
//        set(value){
//            if let value = value{ wrappedO?[keyPath: key] = value }
//        }
//        get{ wrappedO?[keyPath: key] }
//    }
//
//    @_disfavoredOverload
//    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Wrapped, V>) -> V? {
//        nonmutating set(value) {
//            if let value = value{ wrappedO?[keyPath: key] = value }
//        }
//        get { wrappedO?[keyPath: key] }
//    }
//}

extension Optional: TestProtocolfsdf{
//    var wrapper: OptionalWrapper1<Wrapped>{
//        get{ .init(wrappedO: self) }
//        set(new){ self = new.wrappedO }
//    }
    
    
    subscript<V>(dynamicMember key: KeyPath<Wrapped, Optional<V>>) -> V? { self?[keyPath: key] }

    subscript<V>(dynamicMember key: WritableKeyPath<Wrapped, Optional<V>>) -> V? {
        set(value){ self?[keyPath: key] = value }
        get{ self?[keyPath: key] }
    }

    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Wrapped, Optional<V>>) -> V? {
        nonmutating set(value) { self?[keyPath: key] = value }
        get { self?[keyPath: key] }
    }

    @_disfavoredOverload
    subscript<V>(dynamicMember key: KeyPath<Wrapped, V>) -> V? { self?[keyPath: key] }

    @_disfavoredOverload
    subscript<V>(dynamicMember key: WritableKeyPath<Wrapped, V>) -> V? {
        set(value){
            if let value = value{ self?[keyPath: key] = value }
        }
        get{ self?[keyPath: key] }
    }

    @_disfavoredOverload
    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Wrapped, V>) -> V? {
        nonmutating set(value) {
            if let value = value{ self?[keyPath: key] = value }
        }
        get { self?[keyPath: key] }
    }

    func addKeyPath<Value, MainValue, MainKey: KeyPath<MainValue, Self>, Key: KeyPath<Wrapped, Value>>(
        mainKey: MainKey,
        key: Key
    ) -> KeyPath<MainValue, Value>?{
        if self != nil{ return mainKey.appending(path: \.unsafelyUnwrapped).appending(path: key) }
        else { return nil }
//        let a = mainKey.appending(path: (\.?).appending(path: key))
    }
}

//@dynamicMemberLookup
//struct TestStrider<Subject, MainSubject, MainC: ContainerProto<MainSubject>>{
//    private var mainC: MainC
//    private var c: Container<Subject>
//
//
//    init(_ subject: Subject) where Subject: AnyObject, MainC == Container<Subject>{
//        c = .init(setAction: {_ in }, getAction: { subject })
//        mainC = c
//    }
//
//    init(_ subject: UnsafeMutablePointer<Subject>) where MainC == Container<Subject> {
//        c = .init(setAction: {subject.pointee = $0}, getAction: {subject.pointee})
//        mainC = c
//    }
//
//    init(c: Container<Subject>) where MainC == Container<Subject>{
//        self.mainC = c
//        self.c = c
//    }
//
//    init(
//        mainC: MainC,
//        c: Container<Subject>
//    ){
//        self.mainC = mainC
//        self.c = c
//    }
//
//    subscript<V>(dynamicMember key: WritableKeyPath<Subject, V>) -> TestStrider<V, MainSubject, MainC>{
//        .init(
//            mainC: mainC,
//            c: .init(setAction: { value in
//                guard var old = c.getAction() else { return }
//                old[keyPath: key] = value
//                c.setAction(old)
//            }, getAction: {
//                c.getAction()?[keyPath: key]
//            })
//        )
//    }
//
//    subscript<V>(dynamicMember key: ReferenceWritableKeyPath<Subject, V>) -> TestStrider<V, MainSubject, MainC>{
//        .init(
//            mainC: mainC,
//            c: .init(
//                setAction: { c.getAction()?[keyPath: key] = $0 },
//                getAction: { c.getAction()?[keyPath: key] }
//            )
//        )
//    }
//
//    @discardableResult
//    func callAsFunction(_ value: Subject) -> TestStrider<MainSubject, MainSubject, MainC> where MainC == Container<MainSubject> {
//        c.setAction(value)
//        return .init(c: mainC)
//    }
//}
//

private final class _Key<T> {

    var raw: pthread_key_t

    var box: Box<T>? {
        guard let pointer = pthread_getspecific(raw) else {
            return nil
        }
        return Unmanaged<Box<T>>.fromOpaque(pointer).takeUnretainedValue()
    }

    init() {
        raw = pthread_key_t()
        pthread_key_create(&raw) {
            print("hir")
            // Cast required because argument is optional on some
            // platforms (Linux) but not on others (macOS)
            guard let rawPointer = ($0 as UnsafeMutableRawPointer?) else {
                return
            }
            Unmanaged<AnyObject>.fromOpaque(rawPointer).release()
        }
    }

    deinit {
//        print("remove", (box as! Box<EZObservableKitTest.Dier>).value.int)
//        pthread_setspecific(raw, nil)
        
        pthread_key_delete(raw)
    }

    func box(create: () throws -> T) rethrows -> Box<T> {
        if let box = self.box {
            return box
        } else {
            let box = try Box(create())
            pthread_setspecific(raw, Unmanaged.passRetained(box).toOpaque())
            return box
        }
    }

}

/// A reference to a heap-allocated value.
public final class Box<Value> {

    /// The boxed value.
    public var value: Value

    /// Creates an instance that boxes `value`.
    public init(_ value: Value) {
        self.value = value
    }

    deinit{
        print("Box die")
    }
}

 
/// A type that takes an initializer to create and then store a value that's
/// unique to the current thread. The initializer is called the first time
/// the thread-local is accessed, either through `inner` or `withValue(_:)`.
///
/// - note: If the initial value isn't known until retrieval, use `DeferredThreadLocal`.
public struct ThreadLocal<Value>: Hashable, @unchecked Sendable {

    fileprivate var _def: DeferredThreadLocal<Value>

    private var _create: () -> Value

    /// The hash value.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(_def.hashValue)
    }

    /// Returns the inner boxed value for the current thread.
    public var inner: Box<Value> {
        return _def.inner(createdWith: _create)
    }

    /// Creates an instance that will use `value` captured in its current
    /// state for an initial value.
    ///
    /// Sometimes this is what you want such as in cases where `value` is
    /// the result of an expensive operation or a copy-on-write type like
    /// `Array` or `Dictionary`.
    public init(capturing value: Value) {
        self.init { [value] in
            value
        }
    }

    /// Creates an instance that will use `value` for an initial value.
    public init(value: @escaping @autoclosure () -> Value) {
        self.init(create: value)
    }

    /// Creates an instance that will use `create` to generate an initial value.
    public init(create: @escaping () -> Value) {
        _create = create
        _def = DeferredThreadLocal()
    }

    /// Creates an instance that uses the same storage as `deferred` but with
    /// `create` as an initializer.
    public init(fromDeferred deferred: DeferredThreadLocal<Value>, create: @escaping () -> Value) {
        _create = create
        _def = deferred
    }

    /// Returns the result of the closure performed on the value of `self`.
    public func withValue<T>(_ body: (inout Value) throws -> T) rethrows -> T {
        return try body(&inner.value)
    }

}

/// A type that stores a value unique to the current thread. An initial value
/// isn't provided until the inner thread-local value is accessed.
///
/// - note: If the initial value is known at the time of initialization of the
///         enclosing type, consider using `ThreadLocal` instead.
public struct DeferredThreadLocal<Value>: Hashable {

    fileprivate var _key: _Key<Value>

    public func hash(into hasher: inout Hasher) {
        hasher.combine(_key.raw.hashValue)
    }

    /// Returns the inner boxed value for the current thread if it's been
    /// created, or `nil` otherwise.
    public var inner: Box<Value>? {
        return _key.box
    }

    /// Creates an instance.
    public init() {
        _key = _Key()
    }

    /// Returns the inner boxed value for the current thread,
    /// created with `create` if not previously initialized.
    public func inner(createdWith create: () throws -> Value) rethrows -> Box<Value> {
        return try _key.box(create: create)
    }

    /// Returns the result of the closure performed on the inner thread-local
    /// value of `self`, or `nil` if uninitialized.
    public func withValue<T>(_ body: (inout Value) throws -> T) rethrows -> T? {
        return try inner.map { try body(&$0.value) }
    }

    /// Returns the result of the closure performed on the inner thread-local
    /// value of `self`, created with `create` if not previously initialized.
    public func withValue<T>(createdWith create: () throws -> Value, _ body: (inout Value) throws -> T) rethrows -> T {
        return try body(&inner(createdWith: create).value)
    }

}

/// A type that has a static thread-local instance.
public protocol ThreadLocalRetrievable {

    /// The thread-local boxed instance of `Self`.
    static var threadLocal: Box<Self> { get }

    /// Returns the result of performing the closure on the thread-local instance of `Self`.
    static func withThreadLocal<T>(_ body: (inout Self) throws -> T) rethrows -> T

}

extension ThreadLocalRetrievable {
    /// Returns the result of performing the closure on the thread-local instance of `Self`.
    public static func withThreadLocal<T>(_ body: (inout Self) throws -> T) rethrows -> T {
        return try body(&threadLocal.value)
    }
}

/// Returns a Boolean value that indicates whether the two arguments have equal values.
public func ==<T, U>(lhs: ThreadLocal<T>, rhs: ThreadLocal<U>) -> Bool {
    return lhs._def == rhs._def
}

/// Returns a Boolean value that indicates whether the two arguments have equal values.
public func ==<T, U>(lhs: DeferredThreadLocal<T>, rhs: DeferredThreadLocal<U>) -> Bool {
    return lhs._key.raw == rhs._key.raw
}
