//
//  EZSUIPackViewProtocol.swift
//  EZSUIPackKit
//
//  Created by Александр Сенин on 07.02.2026.
//

#if canImport(SwiftUI)
import SwiftUI

/// Protocol for SwiftUI views in the IMV architecture.
///
/// Combines `EZPackViewBaseProtocol`, SwiftUI `View`, and `Equatable` to create a view
/// that integrates with the IMV pattern. The view model is accessible as a read-only property.
///
/// ### Example
/// ```swift
/// struct ProfileView: EZSUIPackV {
///     let access = ProfilePackM.accessV
///
///     func makeInput() -> Mediator.InputV { self }
///
///     var body: some View {
///         VStack {
///             Text(viewModel.name)
///             Button("Load") { inputI.loadProfile() }
///         }
///     }
/// }
/// ```
///
/// - Note: Use `EZSUIPackV` (which is `View & EZSUIPackViewProtocol`) as your base type.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public protocol EZSUIPackViewProtocol: EZPackViewBaseProtocol, View, Equatable
    where Mediator: EZSUIPackMediatorProtocol
{}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackViewProtocol {
    /// Always returns `false` to ensure SwiftUI treats each view instance as unique.
    nonisolated static public func ==(lhs: Self, rhs: Self) -> Bool { false }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackViewProtocol {
    /// Read-only access to the mediator's view model.
    public var viewModel: Mediator.ViewModel {
        _read { yield self.access.viewModel }
    }

    /// Read-only access to the interactor's action interface.
    public var inputI: Mediator.InputI {
        _read { yield self.access.inputI }
    }
}

/// The primary type for creating SwiftUI views in the IMV architecture.
///
/// `EZSUIPackV` is a type alias that combines `View` and `EZSUIPackViewProtocol`.
/// This is the **recommended base type** for all SwiftUI view implementations in EZSUIPackKit.
///
/// ### Example
/// ```swift
/// struct MyView: EZSUIPackV {
///     let access = MyPackM.accessV
///     func makeInput() -> Mediator.InputV { self }
///
///     var body: some View {
///         Text(viewModel.title)
///     }
/// }
/// ```
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZSUIPackV = View & EZSUIPackViewProtocol
#endif
