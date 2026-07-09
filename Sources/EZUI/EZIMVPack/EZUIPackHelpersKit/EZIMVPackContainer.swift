//
//  EZIMVPackContainer.swift
//  EZUIPackHelpersKit
//
//  Created by Александр Сенин on 07.02.2026.
//

#if canImport(Combine)
import Combine
#endif

/// Holds the deferred mediator assignment shared by the access objects.
///
/// When Combine is available, the container is also the invalidation cell: `observe(_:)`
/// forwards the view model's `objectWillChange` into the container's own publisher, which
/// SwiftUI watches through the access's `@ObservedObject` wrapper.
@MainActor
final class EZIMVPackContainer<Value> {
    private var value: Value?
    #if canImport(Combine)
    private var cancellable: AnyCancellable?
    #endif

    func get() -> Value {
        guard let value else { fatalError("Use the access only after the `didInitialize()` was called.") }
        return value
    }
    func set(_ value: Value) { self.value = value }
}

#if canImport(Combine)
extension EZIMVPackContainer: ObservableObject {}

extension EZIMVPackContainer {
    func observe(_ observable: some ObservableObject) {
        guard cancellable == nil else { return }
        cancellable = observable.willChangeSync { [weak self] in
            self?.objectWillChange.send()
        }
    }
}
#endif
