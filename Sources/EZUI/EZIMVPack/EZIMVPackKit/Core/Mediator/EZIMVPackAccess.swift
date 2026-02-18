//
//  EZIMVPackAccess.swift
//  EZIMVPackKit
//
//  Created by Александр Сенин on 07.02.2026.
//

import Foundation

// MARK: - MappedAccess

/// A `@dynamicMemberLookup` proxy that exposes selected properties of an object via an access map.
///
/// `EZIMVPackMappedAccess` is the foundation of the IMV access control system. It allows interactors
/// and views to access only the mediator properties explicitly listed in the access map,
/// providing compile-time safety for the communication boundary.
///
/// The access map is a struct whose properties are key paths into the target object.
/// Read-only key paths produce read-only subscripts; `ReferenceWritableKeyPath` produces
/// read-write subscripts.
///
/// ### Example: Custom access map
/// ```swift
/// struct MyAccessMap {
///     var userName: KeyPath<MyMediator, String>
///     var score: ReferenceWritableKeyPath<MyMediator, Int>
/// }
///
/// // Usage:
/// let access = EZIMVPackMappedAccess(mediator, accessMap: MyAccessMap(
///     userName: \.userName,
///     score: \.score
/// ))
/// let name = access.userName       // read-only
/// access.score = 42                // read-write
/// ```
@MainActor
@dynamicMemberLookup
open class EZIMVPackMappedAccess<Object: AnyObject, AccessMap> {
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

@MainActor
class EZIMVPackContainer<Value> {
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

/// The interactor's access object to the mediator.
///
/// Provides the interactor with:
/// - `viewModel` — read/write access to the shared view model
/// - `inputV` — read-only access to the view's action interface
/// - Dynamic member access to properties defined in the access map
///
/// Created via `MyMediator.accessI` and assigned in the interactor:
/// ```swift
/// class MyPackI: EZUIPackI {
///     let access = MyPackM.accessI
/// }
/// ```
///
/// - Important: Accessing the mediator before `didInitialize()` is called will trigger a fatal error.
@MainActor
public class EZIMVPackAccessI<
    Mediator: EZIMVPackMediatorProtocol, AccessMap
>: EZIMVPackMappedAccess<Mediator, AccessMap> {
    private var container = EZIMVPackContainer<Mediator>(
        errorMessage: "Use the access only after the `didInitialize()` was called."
    )
    package var mediator: Mediator { container.get() }

    public var viewModel: Mediator.ViewModel {
        get { mediator.viewModel }
        set { mediator.viewModel = newValue }
    }

    public var inputV: Mediator.InputV {
        get { mediator.inputV }
    }

    package func setMediator(_ mediator: Mediator) { container.set(mediator) }

    public init(_ mediator: Mediator? = nil, accessMap: AccessMap) {
        super.init({[container] in container.get() }, accessMap: accessMap)
        mediator.map { container.set($0) }
    }
}

// MARK: - AccessV

/// The view's access object to the mediator.
///
/// Provides the view with:
/// - `viewModel` — read/write access to the shared view model
/// - `inputI` — read-only access to the interactor's action interface
/// - Dynamic member access to properties defined in the access map
///
/// Created via `MyMediator.accessV` and assigned in the view:
/// ```swift
/// class MyIOSV: EZUIPackV {
///     let access = MyPackM.accessV
/// }
/// ```
///
/// - Important: Accessing the mediator before `didInitialize()` is called will trigger a fatal error.
@MainActor
open class EZIMVPackAccessV<
    Mediator: EZIMVPackMediatorProtocol, AccessMap
>: EZIMVPackMappedAccess<Mediator, AccessMap> {
    private var container = EZIMVPackContainer<Mediator>(
        errorMessage: "Use the access only after the `didInitialize()` was called."
    )
    package var mediator: Mediator { container.get() }

    package func setMediator(_ mediator: Mediator) {
        container.set(mediator)
    }

    public var viewModel: Mediator.ViewModel {
        get { mediator.viewModel }
        set { mediator.viewModel = newValue }
    }

    public var inputI: Mediator.InputI {
        get { mediator.inputI }
    }

    public init(_ mediator: Mediator? = nil, accessMap: AccessMap) {
        super.init({[container] in container.get() }, accessMap: accessMap)
        mediator.map { container.set($0) }
    }
}
