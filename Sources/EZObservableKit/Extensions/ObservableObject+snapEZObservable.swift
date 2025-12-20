//
//  ObservableObject+snapEZObservable.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.02.2025.
//

/// Helpers to bridge `EZObservableProtocol` values into SwiftUI's `ObservableObject` refresh cycle.
///
/// These helpers subscribe to one or more observables and forward their change events into
/// `objectWillChange.send()`, causing SwiftUI views bound to the `ObservableObject` to update.
///
/// Subscriptions are anchored to `self` via `snapToObject(_:)`, so they are automatically removed
/// when the `ObservableObject` is deallocated.
#if canImport(SwiftUI)
import SwiftUI
import Combine

/// Convenience API to "snap" `EZObservableProtocol` instances to `objectWillChange`.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension ObservableObject {
    /// Subscribes to the given observables and forwards their events to `objectWillChange`.
    ///
    /// Each observable is subscribed with main-actor isolation and, on every event, this method
    /// calls `objectWillChange.send()`.
    ///
    /// - Parameter observers: An array of observables to observe.
    ///
    /// ### Example
    /// ```swift
    /// @MainActor
    /// final class ViewModel: ObservableObject {
    ///     @EZObservable var title: String = ""
    ///     @EZObservable var count: Int = 0
    ///
    ///     init() {
    ///         snapEZObservable($title, $count)
    ///     }
    ///
    ///     func inc() {
    ///         _count.update { $0.value += 1 }
    ///     }
    /// }
    ///
    /// struct ContentView: View {
    ///     @StateObject private var vm = ViewModel()
    ///
    ///     var body: some View {
    ///         VStack(spacing: 12) {
    ///             Text(vm.title)
    ///             Text("Count: \(vm.count)")
    ///
    ///             Button("Increment") {
    ///                 vm.inc()
    ///             }
    ///         }
    ///         .padding()
    ///     }
    /// }
    /// ```
    public func snapEZObservable(_ observers: [any EZObservableProtocol]) {
        guard let objectWillChange = objectWillChange as? ObservableObjectPublisher else { return }
        observers.forEach {
            $0.unknownAddWithIsolation(isolation: MainActor.shared, wrapper: nil) {_ in
                objectWillChange.send()
            }.snapToObject(self)
        }
    }
    
    /// Variadic convenience overload of `snapEZObservable(_:)`.
    public func snapEZObservable(_ observers: any EZObservableProtocol...) {
        snapEZObservable(observers)
    }
    
    /// Automatically discovers `EZObservableProtocol` properties via reflection and snaps them.
    ///
    /// This method uses `Mirror` to scan the object's stored properties and collects those that
    /// conform to `EZObservableProtocol`.
    ///
    /// - Note: Reflection can be brittle (e.g. with computed properties or storage that is not
    ///   directly visible to `Mirror`). Prefer the explicit overloads when possible.
    ///
    /// ### Example
    /// ```swift
    /// @MainActor
    /// final class ViewModel: ObservableObject {
    ///     @EZObservable var title: String = ""
    ///     @EZObservable var count: Int = 0
    ///
    ///     init() {
    ///         snapEZObservable() // discovers and snaps all EZObservableProtocol fields
    ///     }
    /// }
    /// ```
    public func snapEZObservable() {
        let mirror = Mirror(reflecting: self)
        snapEZObservable(
            mirror.children.compactMap { $0.value as? (any EZObservableProtocol) }
        )
    }
}
#endif
