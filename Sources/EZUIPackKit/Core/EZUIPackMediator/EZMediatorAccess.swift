//
//  EZMediatorAccess.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

#if canImport(UIKit) && !os(watchOS)

import Foundation

import EZHelpersKit

class MediatorAccessContainer<Value> {
    private var value: Value?
    private let errorMessage: String
    
    func get() -> Value {
        guard let value else { fatalError(errorMessage) }
        return value
    }
    func set(_ value: Value) { self.value = value }
    
    init(value: Value? = nil, errorMessage: String) {
        self.value = value
        self.errorMessage = errorMessage
    }
}

public class EZMediatorAccessI<Mediator: EZUIPackMediatorProtocol, AccessMap>: EZMappedAccess<Mediator, AccessMap> {
    private var container = MediatorAccessContainer<Mediator>(
        errorMessage: "Use the access only after the `didInitialize()` was called."
    )
    private var mediator: Mediator { container.get() }
    
    @MainActor
    public var viewModel: Mediator.ViewModel {
        get { mediator.viewModel }
        set { mediator.viewModel = newValue }
    }
    
    @MainActor
    public var inputV: Mediator.InputV {
        get { mediator.inputV }
    }
    
    public func setMediator(_ mediator: Mediator) { container.set(mediator) }

    init(_ mediator: Mediator? = nil, accessMap: AccessMap) {
        super.init({[container] in container.get() }, accessMap: accessMap)
        mediator.map { container.set($0) }
    }
}

public class EZMediatorAccessV<Mediator: EZUIPackMediatorProtocol, AccessMap>: EZMappedAccess<Mediator, AccessMap> {
    private var container = MediatorAccessContainer<Mediator>(
        errorMessage: "Use the access only after the `didInitialize()` was called."
    )
    private var mediator: Mediator { container.get() }
    
    public func setMediator(_ mediator: Mediator) { container.set(mediator) }
    
    @MainActor
    public var packBridge: EZUIPackBridge {
        get { mediator.packBridge }
    }
    
    @MainActor
    public var viewModel: Mediator.ViewModel {
        get { mediator.viewModel }
        set { mediator.viewModel = newValue }
    }
    
    @MainActor
    public var inputI: Mediator.InputI {
        get { mediator.inputI }
    }

    init(_ mediator: Mediator? = nil, accessMap: AccessMap) {
        super.init({[container] in container.get() }, accessMap: accessMap)
        mediator.map { container.set($0) }
    }
}

extension EZUIPackMediatorProtocol {
    public static var accessI: AccessI { .init(accessMap: accessMapI) }
    public static var accessV: AccessV { .init(accessMap: accessMapV) }
    
    static func rKey<Value>(
        _ keyPath: KeyPath<Self, Value>
    ) -> KeyPath<Self, Value> { keyPath }
    
    static func rwKey<Value>(
        _ keyPath: ReferenceWritableKeyPath<Self, Value>
    ) -> ReferenceWritableKeyPath<Self, Value> { keyPath }
}

extension EZUIPackMediatorProtocol where AccessMapI == () {
    public static var accessMapI: AccessMapI { () }
}

extension EZUIPackMediatorProtocol where AccessMapV == () {
    public static var accessMapV: AccessMapV { () }
}

#endif
