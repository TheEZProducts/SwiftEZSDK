//
//  EZUIPackSViewProtocol.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

#if canImport(SwiftUI) && canImport(UIKit) && !os(watchOS)
import SwiftUI

import EZSwiftUIBridgeKit

/// Protocol for views built with SwiftUI in the IMV architecture.
///
/// Allows you to use SwiftUI `View` components within the IMV pattern. The protocol automatically
/// wraps SwiftUI views in a `UIView` container and handles `ObservableObject` integration for
/// reactive updates.
///
/// ### Example: SwiftUI view implementation with struct-based actions
///
/// Since SwiftUI views are structs and cannot be weak references, the mediator should use
/// struct-based `InputV` with closures instead of protocols:
///
/// ```swift
///
/// // In SwiftUI View:
/// struct ProfileIOSV: View, EZUIPackSViewProtocol {
///     let access = ProfilePackM.accessV
///     
///     func makeContext() -> Mediator.ContextV {
///         .init(actions: .init(
///             showError: { message in
///                 // Show error alert
///                 print("Error: \(message)")
///             }
///         ))
///     }
///     
///     var body: some View {
///         VStack {
///             Text(viewModel.profile?.name ?? "")
///             Button("Edit") {
///                 inputI.editProfile()
///             }
///         }
///     }
/// }
/// ```
///
/// - Note: If your `viewModel` conforms to `ObservableObject`, it will automatically be
///   observed for changes, triggering SwiftUI updates.
/// - Important: SwiftUI views are structs and cannot be weak references. Always use struct-based
///   `InputV` with closures in the mediator when working with SwiftUI views.
@MainActor
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol EZUIPackSViewProtocol: EZUIPackViewProtocol, Equatable {
    /// The type of the SwiftUI view body.
    associatedtype Body : View
    
    /// The SwiftUI view body that defines the view's content.
    ///
    /// Use `@ViewBuilder` to compose your SwiftUI UI here.
    @ViewBuilder @MainActor @preconcurrency var body: Self.Body { get }
    
    /// Additional observable objects to observe alongside the view model.
    ///
    /// Override this to provide additional `ObservableObject` instances that should trigger
    /// SwiftUI updates when they change.
    var additionalObservableObjects: [any ObservableObject] { get }
    
    /// Creates a new SwiftUI view instance.
    init()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol{
    /// Default implementation: returns an empty array.
    ///
    /// Override to provide additional observable objects for SwiftUI updates.
    public var additionalObservableObjects: [any ObservableObject] { [] }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPackSViewProtocol where Self: View {
    /// Access to the underlying `UIView` of the interactor, if available.
    ///
    /// Useful for advanced integration scenarios where you need direct access to the UIKit view.
    public var uiView: EZView? { packBridge.pack?.interactor?.view }
    
    /// Returns a `UIView` wrapper containing this SwiftUI view.
    ///
    /// Automatically wraps the SwiftUI view in a `UIView` container and sets up
    /// `ObservableObject` observation if the view model conforms to `ObservableObject`.
    ///
    /// - Returns: A configured `UIView` ready for display.
    public func getView() -> EZView {
        if let observObj = access.viewModel as? (any ObservableObject) {
            return .ezWrap(
                EZObservableObjectGroup(objects: additionalObservableObjects + [observObj])
            ){ self }
        }else{
            return .ezWrap(
                EZObservableObjectGroup(objects: additionalObservableObjects),
                view: self
            )
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol where Self: View {
    /// Equality comparison that always returns `false`.
    ///
    /// This ensures SwiftUI treats each view instance as unique, preventing unwanted reuse.
    nonisolated
    public static func ==(l: Self, r: Self) -> Bool { false }
    
    /// A binding to the mediator access object.
    ///
    /// Useful for passing access to child SwiftUI views.
    public var bAccess: Binding<Mediator.AccessV> { .constant(access) }
    
    /// A binding to the view model.
    ///
    /// Useful for two-way data binding in SwiftUI views.
    public var bViewModel: Binding<Mediator.ViewModel> { .constant(viewModel) }
    
    /// A binding to the view itself.
    ///
    /// Useful for passing the view to child SwiftUI views.
    public var binding: Binding<Self> { .constant(self) }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol where Self: EZView {
    /// A binding to the mediator access object.
    ///
    /// Useful for passing access to child SwiftUI views.
    public var bAccess: Binding<Mediator.AccessV> { .constant(access) }
    
    /// A binding to the view model.
    ///
    /// Useful for two-way data binding in SwiftUI views.
    public var bViewModel: Binding<Mediator.ViewModel> { .constant(viewModel) }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol where Self: EZView {
    /// Returns this view with the SwiftUI body wrapped as a subview.
    ///
    /// Creates a wrapper view containing the SwiftUI body and sets up autoresizing masks.
    /// Automatically handles `ObservableObject` observation if the view model conforms to it.
    ///
    /// - Returns: This view with the SwiftUI body as a subview.
    public func getView() -> EZView {
        let view = wrappedView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        return self
    }
    
    private func wrappedView() -> EZView {
        if let observObj = access.viewModel as? (any ObservableObject) {
            return .ezWrap(
                EZObservableObjectGroup(objects: additionalObservableObjects + [observObj])
            ) {[weak self] in
                if let self = self { body }
            }
        }else{
            return .ezWrap(
                EZObservableObjectGroup(objects: additionalObservableObjects),
                view: body
            )
        }
    }
}

/// The primary type for creating SwiftUI views in the IMV architecture.
///
/// `EZUIPackSV` is a type alias that combines SwiftUI's `View` protocol with `EZUIPackSViewProtocol`,
/// providing everything you need to create a SwiftUI-based view for packs. This is the
/// **recommended base type** for all SwiftUI view implementations.
///
/// SwiftUI views created with this type:
/// - Automatically integrate with the IMV architecture
/// - Support reactive updates when `viewModel` conforms to `ObservableObject`
/// - Are automatically wrapped in a `UIView` container for UIKit integration
/// - Can access the mediator's view model and interactor's actions
///
/// ## Example: Complete SwiftUI view implementation
///
/// ```swift
/// struct ProfileIOSV: EZUIPackSV {
///     let access = ProfilePackM.accessV
///     
///     func makeContext() -> Mediator.ContextV {
///         .init(actions: .init(
///             showError: { message in
///                 // Handle error display
///             }
///         ))
///     }
///     
///     var body: some View {
///         VStack {
///             if viewModel.isLoading {
///                 ProgressView()
///             } else {
///                 Text(viewModel.profile?.name ?? "No profile")
///                 Button("Edit") {
///                     inputI.editProfile()
///                 }
///             }
///         }
///         .onChange(of: viewModel.profile) { newProfile in
///             // React to view model changes
///         }
///     }
/// }
/// ```
///
/// ## Important Notes
///
/// - **Struct-based actions**: Since SwiftUI views are structs, the mediator's `InputV` should be
///   a struct with closures, not a protocol. See `EZUIPackSViewProtocol` documentation for details.
/// - **ObservableObject**: If your `viewModel` conforms to `ObservableObject`, SwiftUI will
///   automatically observe it and update the view when it changes.
/// - **Access pattern**: Use `access.viewModel` to read/write state, and `access.inputI` to
///   trigger interactor actions.
///
/// - Note: Always use `EZUIPackSV` as your base type for SwiftUI views. It provides the necessary
///   infrastructure for IMV integration and UIKit bridging.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZUIPackSV = View & EZUIPackSViewProtocol

/// Type alias for a `UIView` that also conforms to `EZUIPackSViewProtocol`.
///
/// `EZUIPackSUIV` combines `UIView` with `EZUIPackSViewProtocol`, allowing you to create a
/// UIKit view that wraps SwiftUI content. This is useful when you need a `UIView` subclass
/// that contains SwiftUI views.
///
/// ## Example
///
/// ```swift
/// class ProfileContainerView: EZUIPackSUIV {
///     let access = ProfilePackM.accessV
///     
///     func makeContext() -> Mediator.ContextV {
///         .init(actions: .init(
///             showError: { message in /* ... */ },
///             refreshUI: { /* ... */ }
///         ))
///     }
///     
///     func create() {
///         // Set up UIKit-specific properties
///         backgroundColor = .systemBackground
///     }
///     
///     var body: some View {
///         // SwiftUI content
///         ProfileContentView()
///     }
/// }
/// ```
///
/// - Note: Use this when you need UIKit-specific functionality (like `UIView` subclassing)
///   combined with SwiftUI content.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZUIPackSUIV = UIView & EZUIPackSViewProtocol

#endif
