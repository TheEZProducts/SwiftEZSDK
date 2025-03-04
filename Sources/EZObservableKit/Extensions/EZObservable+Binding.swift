//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation
import EZAsyncKit

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZObservable{
    func binding<BindingValue>(keyPath: ReferenceWritableKeyPath<Value, BindingValue>) -> Binding<BindingValue?>{
        let wrapper = EZUnsafeSendableWrapper(keyPath)
        return .init {[weak storage] in
            storage?.get()[keyPath: wrapper.value]
        } set: {[weak storage] newValue in
            if let newValue{
                storage?.get()[keyPath: wrapper.value] = newValue
                storage?.signal(.common)
            }
        }
    }
    
    func binding<BindingValue>(keyPath: WritableKeyPath<Value, BindingValue>) -> Binding<BindingValue?>{
        let wrapper = EZUnsafeSendableWrapper(keyPath)
        return .init {[weak storage] in
            storage?.get()[keyPath: wrapper.value]
        } set: {[weak storage] newValue in
            if let newValue, var value = storage?.get(){
                value[keyPath: wrapper.value] = newValue
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
