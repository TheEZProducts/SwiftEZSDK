//
//  File.swift
//
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation
import EZAsyncKit

/// Convenience helpers to create a SwiftUI `Binding` (when available) or an `EZBinding` fallback
/// from an `EZObservable` and a key path into its `Value`.
///
/// - On iOS 13+ / macOS 10.15+ (and similar), prefer SwiftUI's `Binding`.
/// - On older platforms without SwiftUI `Binding`, use the `EZBinding` overloads.
///
/// All overloads in this file return an *optional* binding (`BindingValue?`). The setter ignores
/// `nil` assignments.

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZObservable {
    /// Creates a SwiftUI `Binding` to a reference-type field inside the observable's `Value`.
    ///
    /// Use this overload when `Value` is a reference type (or otherwise supports in-place mutation)
    /// and the field is addressed by a `ReferenceWritableKeyPath`.
    ///
    /// The setter updates the field in-place and then calls `signal(.common)` to notify observers.
    ///
    /// ### Example
    /// ```swift
    /// final class Model {
    ///     var name: String = ""
    /// }
    ///
    /// @EZObservable var model: Model = .init()
    ///
    /// // SwiftUI:
    /// let name = $model.binding(keyPath: \Model.name)
    /// name.wrappedValue = "Alice" // updates in-place and signals
    /// ```
    func binding<BindingValue>(keyPath: ReferenceWritableKeyPath<Value, BindingValue>) -> Binding<BindingValue?> {
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
    
    /// Creates a SwiftUI `Binding` to a value-type field inside the observable's `Value`.
    ///
    /// Use this overload when `Value` is a value type and the field is addressed by a `WritableKeyPath`.
    /// The setter performs a copy-on-write style update by reading the current `Value`, mutating a local
    /// copy, and then calling `set(value: .common)`.
    ///
    /// ### Example
    /// ```swift
    /// struct State {
    ///     var count: Int = 0
    /// }
    ///
    /// @EZObservable var state: State = .init()
    ///
    /// // SwiftUI:
    /// let count = $state.binding(keyPath: \State.count)
    /// count.wrappedValue = 1 // sets a new State and notifies
    /// ```
    func binding<BindingValue>(keyPath: WritableKeyPath<Value, BindingValue>) -> Binding<BindingValue?> {
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

extension EZObservable {
    /// Creates an `EZBinding` fallback to a reference-type field inside the observable's `Value`.
    ///
    /// This is the non-SwiftUI equivalent of the `Binding` overload above and is intended primarily
    /// for deployment targets where SwiftUI `Binding` is not available.
    ///
    /// The setter updates the field in-place and then calls `signal(.common)`.
    ///
    /// ### Example
    /// ```swift
    /// final class Model {
    ///     var name: String = ""
    /// }
    ///
    /// let model = EZObservable(wrappedValue: Model())
    /// let name = model.binding(keyPath: \Model.name)
    /// name.wrappedValue = "Alice"
    /// ```
    @_disfavoredOverload
    func binding<BindingValue>(keyPath: ReferenceWritableKeyPath<Value, BindingValue>) -> EZBinding<BindingValue?> {
        .init {[weak storage, keyPath = EZUnsafeSendableWrapper(keyPath)] in
            storage?.get()[keyPath: keyPath.value]
        } set: {[weak storage, keyPath = EZUnsafeSendableWrapper(keyPath)] newValue in
            if let newValue{
                storage?.get()[keyPath: keyPath.value] = newValue
                storage?.signal(.common)
            }
        }
    }
    
    /// Creates an `EZBinding` fallback to a value-type field inside the observable's `Value`.
    ///
    /// The setter performs a copy-on-write style update by reading the current `Value`, mutating a local
    /// copy, and then calling `set(value: .common)`.
    ///
    /// ### Example
    /// ```swift
    /// struct State {
    ///     var count: Int = 0
    /// }
    ///
    /// let state = EZObservable(wrappedValue: State())
    /// let count = state.binding(keyPath: \State.count)
    /// count.wrappedValue = 1
    /// ```
    @_disfavoredOverload
    func binding<BindingValue>(keyPath: WritableKeyPath<Value, BindingValue>) -> EZBinding<BindingValue?> {
        .init {[weak storage, keyPath = EZUnsafeSendableWrapper(keyPath)] in
            storage?.get()[keyPath: keyPath.value]
        } set: {[weak storage, keyPath = EZUnsafeSendableWrapper(keyPath)] newValue in
            if let newValue, var value = storage?.get(){
                value[keyPath: keyPath.value] = newValue
                storage?.set(value: value, .common)
            }
        }
    }
}
