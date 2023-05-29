//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

#if canImport(SwiftUI)
import SwiftUI

@available(tvOS 13.0, *)
@available(watchOS 6.0, *)
@available(iOS 13.0, *)
@available(macOS 10.15, *)
extension EZObservable{
    func binding<BindingValue>(keyPath: ReferenceWritableKeyPath<Value, BindingValue>) -> Binding<BindingValue?>{
        .init {[weak storage] in
            storage?.get()[keyPath: keyPath]
        } set: {[weak storage] newValue in
            if let newValue{
                storage?.get()[keyPath: keyPath] = newValue
                storage?.signal(.common)
            }
        }
    }
    
    func binding<BindingValue>(keyPath: WritableKeyPath<Value, BindingValue>) -> Binding<BindingValue?>{
        .init {[weak storage] in
            storage?.get()[keyPath: keyPath]
        } set: {[weak storage] newValue in
            if let newValue, var value = storage?.get(){
                value[keyPath: keyPath] = newValue
                storage?.set(value: value, .common)
            }
        }
    }
}
#endif

extension EZObservable{
    @_disfavoredOverload
    func binding<BindingValue>(keyPath: ReferenceWritableKeyPath<Value, BindingValue>) -> EZBinding<BindingValue?>{
        .init {[weak storage] in
            storage?.get()[keyPath: keyPath]
        } set: {[weak storage] newValue in
            if let newValue{
                storage?.get()[keyPath: keyPath] = newValue
                storage?.signal(.common)
            }
        }
    }
    
    @_disfavoredOverload
    func binding<BindingValue>(keyPath: WritableKeyPath<Value, BindingValue>) -> EZBinding<BindingValue?>{
        .init {[weak storage] in
            storage?.get()[keyPath: keyPath]
        } set: {[weak storage] newValue in
            if let newValue, var value = storage?.get(){
                value[keyPath: keyPath] = newValue
                storage?.set(value: value, .common)
            }
        }
    }
}
