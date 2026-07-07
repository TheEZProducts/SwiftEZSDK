//
//  EZSUIPackAccessV.swift
//  EZSUIPackKit
//
//  Created by Александр Сенин on 04.07.2026.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine

/// The SwiftUI flavor of the view's access object.
///
/// Unlike the plain `EZIMVPackAccessV` class, this is a `DynamicProperty`:
/// storing it in a SwiftUI view (`let access = MyPackM.accessV`) registers
/// that view as a dependency of the pack's view model. When the view model
/// emits `objectWillChange`, SwiftUI invalidates the owning view directly —
/// updates are delivered at the point of use and do not rely on structural
/// diffing anywhere above the view.
///
/// The declaration at the call site is identical to the UIKit flavor:
/// ```swift
/// struct ProfileV: EZSUIPackV {
///     let access = ProfilePackM.accessV
///     var body: some View { Text(viewModel.name) }
/// }
/// ```
@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
@MainActor
@dynamicMemberLookup
public struct EZSUIPackAccessV<
    Mediator: EZSUIPackMediatorProtocol, AccessMap
>: DynamicProperty {

    /// Forwards the view model's `objectWillChange` into the SwiftUI graph
    /// via the enclosing `@ObservedObject`.
    @MainActor
    final class InvalidationBox: ObservableObject {
        private var cancellable: AnyCancellable?

        func observe(_ observable: some ObservableObject) {
            guard cancellable == nil else { return }
            cancellable = observable.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }

    @ObservedObject private var box: InvalidationBox
    private let base: EZIMVPackAccessV<Mediator, AccessMap>

    package var mediator: Mediator { base.mediator }

    public var viewModel: Mediator.ViewModel {
        get { base.viewModel }
        nonmutating set { base.viewModel = newValue }
    }

    public var inputI: Mediator.InputI {
        base.inputI
    }

    public subscript<Value>(
        dynamicMember key: KeyPath<AccessMap, KeyPath<Mediator, Value>>
    ) -> Value {
        base[dynamicMember: key]
    }

    public subscript<Value>(
        dynamicMember key: KeyPath<AccessMap, ReferenceWritableKeyPath<Mediator, Value>>
    ) -> Value {
        get { base[dynamicMember: key] }
        nonmutating set { base[dynamicMember: key] = newValue }
    }

    package func setMediator(_ mediator: Mediator) {
        base.setMediator(mediator)
        if let vm = mediator.viewModel as? (any ObservableObject) {
            box.observe(vm)
        }
    }

    public init(_ mediator: Mediator? = nil, accessMap: AccessMap) {
        let box = InvalidationBox()
        self._box = ObservedObject(wrappedValue: box)
        self.base = .init(mediator, accessMap: accessMap)
        if let mediator, let vm = mediator.viewModel as? (any ObservableObject) {
            box.observe(vm)
        }
    }
}
#endif
