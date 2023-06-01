//
//  File.swift
//  
//
//  Created by Александр Сенин on 30.05.2023.
//

import Foundation

public protocol EZJsonKeyProtocol: Hashable, CaseIterable{
    var rawValue: String { get }
}

public struct EZJsonStriderValue{
    private var _value: Any?
    
    public var value: Any? { _value }
    public var json: [String: Any] { _value as? [String: Any] ?? [:] }
    public var array: [Any] { _value as? [Any] ?? [] }
    public var count: Int{ array.count }
    
    public var bool: Bool { (_value as? Bool) ?? false }
    public var string: String { _value as? String ?? "" }
    public var int: Int { _value as? Int ?? 0 }
    public var double: Double { _value as? Double ?? 0 }
    
    init(value: Any?) { self._value = value }
}

@dynamicMemberLookup
public struct EZJsonStrider<Key: EZJsonKeyProtocol>{
    private var _value: Any?
    
    public func forEach(_ closure: (Self) ->()){
        self().array.forEach { closure(.init($0)) }
    }
    public func forEach(_ closure: (Int, Self) ->()){
        self().array.enumerated().forEach { closure($0.offset, .init($0.element)) }
    }
    
    public subscript(index: Key) -> Self{
        self[index.rawValue]
    }
    public subscript(index: String) -> Self{
        Self(self().json[index])
    }
    public subscript(index: Int) -> Self{
        Self(self().array[safe: index])
    }
    public subscript(dynamicMember key: KeyPath<Key, Key>) -> Self{
        get{ self[Key.allCases.first?[keyPath: key].rawValue ?? ""] }
    }
    
    public func callAsFunction() -> EZJsonStriderValue {
        .init(value: _value)
    }
    
    public func callAsFunction<T>(type: T.Type = T.self, _ defaultValue: T) -> T {
        _value as? T ?? defaultValue
    }
    
    public func callAsFunction<T>(type: T.Type = T.self) -> T? {
        _value as? T
    }
    
    public func callAsFunction<T>(_ transform: (Any?) -> (T)) -> T {
        transform(_value)
    }
    
    public init(_ value: Any?){ _value = value }
    public init(name: String, bundle: Bundle = Bundle.main){
        if let path = bundle.path(forResource: name, ofType: ""){
            self.init(path: path)
        }else{
            self.init("non")
        }
    }
    public init(path: String){
        let url: URL
        if #available(macOS 13.0, iOS 16.0, tvOS 16.0, watchOS 9.0, *) {
            url = URL(filePath: #file)
        } else {
            url = URL(fileURLWithPath: #file)
        }
        self.init(url: url)
    }
    public init(url: URL){
        guard
            let data = try? Data(contentsOf: url),
            let json = try? JSONSerialization.jsonObject(with: data)
        else{ self.init("non"); return }
        self.init(json)
    }
}

public struct EZJsonStriderGroupValue{
    private var _values: [EZJsonStriderValue]
    
    public var value: Any? { cast(nil){ $0 } }
    public var json: [String: Any] { cast([:]){ $0 as? [String: Any] } }
    public var array: [Any] { cast([]){ $0 as? [Any] } }
    public var count: Int{ array.count }
    
    public var bool: Bool { cast(false){ $0 as? Bool } }
    public var string: String { cast(""){ $0 as? String } }
    public var int: Int { cast(0){ $0 as? Int } }
    public var double: Double { cast(0){ $0 as? Double } }
    
    private func cast<T>(_ defaultValue: T, _ closure: (Any?) -> (T?)) -> T{
        for value in _values{
            if let value = closure(value.value) { return value }
        }
        return defaultValue
    }
    
    init(values: [EZJsonStriderValue]) { self._values = values }
}

@dynamicMemberLookup
public struct EZJsonStriderGroup<Key: EZJsonKeyProtocol>{
    public private(set) var striders: [EZJsonStrider<Key>]
        
    public func forEach(_ closure: (Self) ->()){
        self().array.enumerated().forEach {
            closure(self[$0.offset])
        }
    }
    public func forEach(_ closure: (Int, Self) ->()){
        self().array.enumerated().forEach {
            closure($0.offset, self[$0.offset])
        }
    }
    
    public subscript(index: Key) -> Self{
        .init( striders.map { $0[index] } )
    }
    public subscript(index: String) -> Self{
        .init( striders.map { $0[index] } )
    }
    public subscript(index: Int) -> Self{
        .init( striders.map { $0[index] } )
    }
    public subscript(dynamicMember key: KeyPath<Key, Key>) -> Self{
        get{ self[Key.allCases.first?[keyPath: key].rawValue ?? ""] }
    }
    
    public func callAsFunction() -> EZJsonStriderGroupValue {
        .init(values: striders.map{ $0() })
    }
    
    public func callAsFunction<T>(type: T.Type = T.self, _ defaultValue: T) -> T {
        cast(defaultValue) { $0 as? T }
    }
    
    public func callAsFunction<T>(type: T.Type = T.self) -> T? {
        cast(nil) { $0 as? T }
    }
    
    public func callAsFunction<T>(_ transform: (Any?) -> (T?)) -> T? {
        cast(nil, transform)
    }
    
    public func callAsFunction<T>(_ defaultValue: T, _ transform: (Any?) -> (T?)) -> T {
        cast(defaultValue, transform)
    }
    
    public func callAsFunction(at: Int) -> EZJsonStriderValue {
        striders[safe: at]?() ?? .init(value: nil)
    }
    
    private func cast<T>(_ defaultValue: T, _ closure: (Any?) -> (T?)) -> T{
        for strider in striders{
            if let value = closure(strider().value) { return value }
        }
        return defaultValue
    }
    
    public init(_ striders: [EZJsonStrider<Key>]){
        self.striders = striders
    }
}

extension Array{
    subscript(safe index: Int) -> Element?{
        indices.contains(index) ? self[index] : nil
    }
}
