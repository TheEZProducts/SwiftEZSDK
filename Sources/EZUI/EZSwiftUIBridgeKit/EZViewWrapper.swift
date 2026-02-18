//
//  EZViewWrapper.swift
//
//
//  Created by Александр Сенин on 04.06.2023.
//

/// SwiftUI ↔︎ platform view bridging helpers.
///
/// This file provides small utilities to embed SwiftUI views into `EZView` (UIKit `UIView` /
/// AppKit `NSView`) and to drive SwiftUI updates from one or multiple `ObservableObject`s.

#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(Combine)
import Combine
#endif
#if canImport(Cocoa)
import Cocoa
#endif

#if canImport(Combine)
/// An `ObservableObject` that forwards `objectWillChange` from a group of `ObservableObject`s.
///
/// This is useful when a single SwiftUI view needs to refresh when *any* of several objects changes.
/// The group subscribes to each object's `objectWillChange` publisher and re-emits it.
///
/// - Note: The created `AnyCancellable`s are stored in `keys` to keep subscriptions alive.
///
/// ### Example
/// ```swift
/// @MainActor
/// final class A: ObservableObject { @Published var value = 0 }
/// @MainActor
/// final class B: ObservableObject { @Published var text = "" }
///
/// let group = EZObservableObjectGroup(A(), B())
/// // Use `group` as a single `ObservableObject` dependency.
/// ```
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public class EZObservableObjectGroup: ObservableObject {
    /// Objects whose `objectWillChange` events are forwarded.
    public var objects: [any ObservableObject]
    /// Stored subscriptions to keep forwarding alive.
    public var keys = [AnyCancellable]()
    
    /// Creates a group from a variadic list of objects.
    public convenience init(_ objects: (any ObservableObject)...){
        self.init(objects: objects)
    }
    /// Creates a group from an array of objects.
    public init(objects: [any ObservableObject]){
        self.objects = objects
        keys = objects.map { addObserver(observObj: $0) }
    }
    
    private func addObserver<ObservObj: ObservableObject>(observObj: ObservObj) -> AnyCancellable{
        observObj.objectWillChange.sink{[weak self] _ in self?.objectWillChange.send()}
    }
}
#endif
 
#if (canImport(UIKit) || canImport(Cocoa)) && !os(watchOS)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZView{
    /// Wraps a SwiftUI `View` into an `EZView` (UIKit/AppKit view) and observes an `ObservableObject`.
    ///
    /// When `observable.objectWillChange` emits, the hosted SwiftUI view is refreshed.
    ///
    /// This overload accepts a pre-built SwiftUI `view` value.
    ///
    /// ### Example
    /// ```swift
    /// @MainActor
    /// final class VM: ObservableObject {
    ///     @Published var title: String = "Hello"
    /// }
    ///
    /// let vm = VM()
    /// let wrapped: EZView = EZView.ezWrap(vm, view: Text(vm.title))
    /// _ = wrapped
    /// ```
    public static func ezWrap<V: View, ObservObj: ObservableObject>(
        _ observable: ObservObj = EZViewWrapperObservable(),
        view: V
    ) -> EZView { .ezWrap(observable){_ in view} }
    
    /// Wraps a SwiftUI `View` builder into an `EZView` and observes an `ObservableObject`.
    ///
    /// Use this overload when you want the SwiftUI view to be created lazily.
    ///
    /// ### Example
    /// ```swift
    /// let vm = EZViewWrapperObservable()
    /// let wrapped = EZView.ezWrap(vm) {
    ///     Text("Hello")
    /// }
    /// _ = wrapped
    /// ```
    public static func ezWrap<V: View, ObservObj: ObservableObject>(
        _ observable: ObservObj = EZViewWrapperObservable(),
        @ViewBuilder view: @escaping ()->V
    ) -> EZView { .ezWrap(observable){_ in view()} }
    
    /// Wraps a SwiftUI `View` builder that receives the observed object.
    ///
    /// This is the most flexible overload: you can build the SwiftUI view using the passed `observable`.
    ///
    /// Implementation notes:
    /// - On iOS/tvOS 16+ (UIKit) it uses `UIHostingConfiguration`.
    /// - Otherwise it falls back to a hosting controller (`EZHostingController`).
    /// - On AppKit it uses `NSHostingView` on newer OS versions.
    ///
    /// ### Example
    /// ```swift
    /// @MainActor
    /// final class VM: ObservableObject {
    ///     @Published var count: Int = 0
    /// }
    ///
    /// let vm = VM()
    /// let wrapped = EZView.ezWrap(vm) { vm in
    ///     Text("Count: \(vm.count)")
    /// }
    /// _ = wrapped
    /// ```
    public static func ezWrap<V: View, ObservObj: ObservableObject>(
        _ observable: ObservObj = EZViewWrapperObservable(),
        @ViewBuilder view: @escaping (ObservObj)->V
    ) -> EZView {
        if #available(iOS 16.0, tvOS 16.0, *) {
#if canImport(UIKit)
            return UIHostingConfiguration {
                EZObserveView(observable, view)
                    .ignoresSafeArea()
            }
            .margins(.all, .zero)
            .makeContentView()
#elseif canImport(Cocoa)
            return NSHostingView(rootView: EZObserveView(observable, view))
#endif
        } else {
            let ezController = EZHostingController(rootView: EZObserveView(observable, view))
            
#if canImport(UIKit)
            ezController._disableSafeArea = true
            ezController.view?.backgroundColor = .clear
            let view = ezController.view ?? EZView()
#else
            let view = ezController.view
#endif
            ezController.view = EZView()
            return view
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
/// Minimal `ObservableObject` used as a default refresh driver for `ezWrap`.
///
/// Call `update()` to trigger a SwiftUI refresh of the hosted view.
///
/// This type is primarily a convenience for cases where you don't already have your own
/// `ObservableObject` to drive updates.
///
/// ### Example
/// ```swift
/// let driver = EZViewWrapperObservable()
/// let wrapped = EZView.ezWrap(driver) { _ in
///     Text("Hello")
/// }
/// driver.update() // forces the wrapped SwiftUI view to refresh
/// _ = wrapped
/// ```
public class EZViewWrapperObservable: ObservableObject {
    /// Triggers `objectWillChange`, causing the hosted SwiftUI view to update.
    public func update() { objectWillChange.send() }
    /// Creates a new update driver.
    public init(){}
}

/// An internal SwiftUI view that observes an `ObservableObject` and rebuilds its content on changes.
///
/// Used by `EZView.ezWrap(_:view:)` to bridge platform views with SwiftUI content.
/// You typically don't use this type directly.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct EZObserveView<V: View, ObservObj: ObservableObject>: View {
    @ObservedObject var obj: ObservObj
    private var view: (ObservObj)->V?

    public init(_ obj: ObservObj, _ view: @escaping (ObservObj)->V){
        self.view = view
        self.obj = obj
    }
    
    public var body: some View {
        view(obj)
    }
}
#endif
