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
/// Refines `EZIMVPackViewProtocol` for SwiftUI: the view's `access` is the SwiftUI
/// `DynamicProperty` flavor, so storing it (`let access = MyPackM.accessV`) registers the
/// view as a SwiftUI dependency of the pack's view model. The view model and `inputI`
/// convenience properties are inherited from the base protocol.
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
public protocol EZSUIPackViewProtocol: EZIMVPackViewProtocol, View
    where Mediator: EZSUIPackMediatorProtocol,
          Access == EZIMVPackAccessV<Mediator, Mediator.AccessMapV>
{ }

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
