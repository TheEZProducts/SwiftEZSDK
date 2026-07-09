//
//  EZIMVPackAccessV.swift
//  EZUIPackHelpersKit
//
//  Created by Александр Сенин on 04.07.2026.
//

import EZIMVPackKit
#if canImport(SwiftUI)
import SwiftUI
#endif

/// The view's access object to the mediator — the single flavor used by every view kind
/// (UIKit views, SwiftUI views, SwiftUI-in-UIKit views).
///
/// Created via the mediator's static factory and stored in the view:
/// ```swift
/// let access = MyPackM.accessV
/// ```
///
/// Provides the view with:
/// - `viewModel` — read/write access to the shared view model
/// - `inputI` — read-only access to the interactor's action interface
/// - Dynamic member access to properties defined in the access map
///
/// When `Mediator.ViewModel` conforms to `ObservableObject`, the access conforms to
/// `DynamicProperty`: storing it in a SwiftUI view registers that view as a dependency of the
/// pack's view model, and updates are delivered at the point of use. The subscription is created
/// lazily in `update()`, which SwiftUI calls only for accesses stored in live SwiftUI views —
/// in a UIKit class view (or with a non-observable view model) the access carries no SwiftUI
/// machinery at all.
///
/// - Important: Accessing the mediator before `didInitialize()` is called will trigger a fatal error.
@MainActor
@dynamicMemberLookup
public struct EZIMVPackAccessV<
    Mediator: EZIMVPackMediatorProtocol, AccessMap
>: EZIMVPackViewAccess {
    #if canImport(SwiftUI)
    @ObservedObject private var container = EZIMVPackContainer<Mediator>()
    #else
    private let container = EZIMVPackContainer<Mediator>()
    #endif
    private let map: AccessMap

    package var mediator: Mediator { container.get() }

    public var viewModel: Mediator.ViewModel {
        get { mediator.viewModel }
        nonmutating set { mediator.viewModel = newValue }
    }

    public var inputI: Mediator.InputI {
        mediator.inputI
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
        nonmutating set { mediator[keyPath: map[keyPath: key]] = newValue }
    }

    public func setMediator(_ mediator: Mediator) {
        container.set(mediator)
    }

    public init(accessMap: AccessMap) {
        self.map = accessMap
    }
}

extension EZIMVPackMediatorProtocol {
    /// The access object type for views.
    ///
    /// Provides controlled access to mediator properties via `@dynamicMemberLookup`.
    public typealias AccessV = EZIMVPackAccessV<Self, AccessMapV>

    /// Creates a new access object for views.
    ///
    /// Call this in the view to initialize its `access` property:
    /// ```swift
    /// let access = MyPackM.accessV
    /// ```
    public static var accessV: AccessV { .init(accessMap: accessMapV) }
}

#if canImport(SwiftUI)
extension EZIMVPackAccessV: DynamicProperty where Mediator.ViewModel: ObservableObject {
    /// Called by SwiftUI before each `body` evaluation; binds the view model's
    /// `objectWillChange` to the container.
    ///
    /// SwiftUI always calls `update()` on the main actor; the requirement itself is
    /// nonisolated, hence the explicit hop.
    nonisolated public func update() {
        MainActor.assumeIsolated {
            container.observe(mediator.viewModel)
        }
    }
}
#endif
