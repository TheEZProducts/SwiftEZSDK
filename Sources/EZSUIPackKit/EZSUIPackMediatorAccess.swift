//
//  EZSUIPackMediatorAccess.swift
//  EZSUIPackKit
//
//  Created by Александр Сенин on 07.02.2026.
//

#if canImport(SwiftUI)
import Foundation

// MARK: - Base Mediator Protocol
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public protocol EZPackMediatorBaseProtocol: AnyObject {
    //MARK: - Required Objects
    associatedtype ViewModel
    var viewModel: ViewModel { get set }

    associatedtype InputI
    var inputI: InputI { get }

    associatedtype InputV
    var inputV: InputV { get }

    //MARK: - Access
    typealias AccessI = EZPackMediatorAccessI<Self, AccessMapI>
    typealias AccessV = EZPackMediatorAccessV<Self, AccessMapV>

    associatedtype AccessMapI
    static var accessMapI: AccessMapI { get }

    associatedtype AccessMapV
    static var accessMapV: AccessMapV { get }

    func didInitialize()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZPackMediatorBaseProtocol {
    public func didInitialize() {}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZPackMediatorBaseProtocol where InputI == Void {
    public var inputI: InputI { () }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZPackMediatorBaseProtocol where InputV == Void {
    public var inputV: InputV { () }
}

// MARK: - MappedAccess
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
@dynamicMemberLookup
public class EZPackMappedAccess<Object: AnyObject, AccessMap> {
    private let object: () -> (Object)
    private let map: AccessMap

    public subscript<Value>(dynamicMember key: KeyPath<AccessMap, KeyPath<Object, Value>>) -> Value {
        get { object()[keyPath: map[keyPath: key]] }
    }

    public subscript<Value>(dynamicMember key: KeyPath<AccessMap, ReferenceWritableKeyPath<Object, Value>>) -> Value {
        get { object()[keyPath: map[keyPath: key]] }
        set { object()[keyPath: map[keyPath: key]] = newValue }
    }

    public init(_ object: @escaping () -> (Object), accessMap: AccessMap) {
        self.object = object
        self.map = accessMap
    }

    public convenience init(_ object: Object, accessMap: AccessMap) {
        self.init({ object }, accessMap: accessMap)
    }
}

// MARK: - Mediator Container (deferred mediator assignment)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
class EZPackMediatorContainer<Value> {
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

// MARK: - AccessI
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public class EZPackMediatorAccessI<
    Mediator: EZPackMediatorBaseProtocol, AccessMap
>: EZPackMappedAccess<Mediator, AccessMap> {
    private var container = EZPackMediatorContainer<Mediator>(
        errorMessage: "Use the access only after the `didInitialize()` was called."
    )
    public var mediator: Mediator { container.get() }

    public var viewModel: Mediator.ViewModel {
        get { mediator.viewModel }
        set { mediator.viewModel = newValue }
    }

    public var inputV: Mediator.InputV {
        get { mediator.inputV }
    }

    public func setMediator(_ mediator: Mediator) { container.set(mediator) }

    init(_ mediator: Mediator? = nil, accessMap: AccessMap) {
        super.init({[container] in container.get() }, accessMap: accessMap)
        mediator.map { container.set($0) }
    }
}

// MARK: - AccessV
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public class EZPackMediatorAccessV<
    Mediator: EZPackMediatorBaseProtocol, AccessMap
>: EZPackMappedAccess<Mediator, AccessMap> {
    private var container = EZPackMediatorContainer<Mediator>(
        errorMessage: "Use the access only after the `didInitialize()` was called."
    )
    public var mediator: Mediator { container.get() }

    public func setMediator(_ mediator: Mediator) {
        container.set(mediator)
    }

    public var viewModel: Mediator.ViewModel {
        get { mediator.viewModel }
        set { mediator.viewModel = newValue }
    }

    public var inputI: Mediator.InputI {
        get { mediator.inputI }
    }

    init(_ mediator: Mediator? = nil, accessMap: AccessMap) {
        super.init({[container] in container.get() }, accessMap: accessMap)
        mediator.map { container.set($0) }
    }
}

// MARK: - Static factories
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZPackMediatorBaseProtocol {
    public static var accessI: AccessI { .init(accessMap: accessMapI) }
    public static var accessV: AccessV { .init(accessMap: accessMapV) }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZPackMediatorBaseProtocol where AccessMapI == () {
    public static var accessMapI: AccessMapI { () }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZPackMediatorBaseProtocol where AccessMapV == () {
    public static var accessMapV: AccessMapV { () }
}

// MARK: - Key helpers
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZPackMediatorBaseProtocol {
    public static func rKey<Value>(
        _ keyPath: KeyPath<Self, Value>
    ) -> KeyPath<Self, Value> { keyPath }

    public static func rwKey<Value>(
        _ keyPath: ReferenceWritableKeyPath<Self, Value>
    ) -> ReferenceWritableKeyPath<Self, Value> { keyPath }
}
#endif
