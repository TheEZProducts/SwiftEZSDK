//
//  EZIMVPackAccessI.swift
//  EZUIPackHelpersKit
//
//  Created by Александр Сенин on 07.02.2026.
//

import EZIMVPackKit

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
@dynamicMemberLookup
public final class EZIMVPackAccessI<
    Mediator: EZIMVPackMediatorProtocol, AccessMap
>: EZIMVPackInteractorAccess {
    private let container = EZIMVPackContainer<Mediator>()
    private let map: AccessMap

    package var mediator: Mediator { container.get() }

    public var viewModel: Mediator.ViewModel {
        get { mediator.viewModel }
        set { mediator.viewModel = newValue }
    }

    public var inputV: Mediator.InputV {
        mediator.inputV
    }

    public subscript<Value>(
        dynamicMember key: KeyPath<AccessMap, KeyPath<Mediator, Value>>
    ) -> Value {
        mediator[keyPath: map[keyPath: key]]
    }

    public subscript<Value>(
        dynamicMember key: KeyPath<AccessMap, ReferenceWritableKeyPath<Mediator, Value>>
    ) -> Value {
        get { mediator[keyPath: map[keyPath: key]] }
        set { mediator[keyPath: map[keyPath: key]] = newValue }
    }

    public func setMediator(_ mediator: Mediator) {
        container.set(mediator)
    }

    public init(accessMap: AccessMap) {
        self.map = accessMap
    }
}

extension EZIMVPackMediatorProtocol {
    /// The access object type for interactors.
    ///
    /// Provides controlled access to mediator properties via `@dynamicMemberLookup`.
    public typealias AccessI = EZIMVPackAccessI<Self, AccessMapI>

    /// Creates a new access object for interactors.
    ///
    /// Call this in the interactor to initialize its `access` property:
    /// ```swift
    /// let access = MyPackM.accessI
    /// ```
    public static var accessI: AccessI { .init(accessMap: accessMapI) }
}
