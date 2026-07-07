//
//  EZSUIPackMediatorProtocol.swift
//  EZSUIPackKit
//
//  Created by Александр Сенин on 07.02.2026.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine

/// Protocol for mediators in the SwiftUI IMV architecture.
///
/// Extends `EZIMVPackMediatorProtocol` for SwiftUI. When `ViewModel` conforms to
/// `ObservableObject`, SwiftUI view updates happen automatically. Use `Void` when
/// no shared state is needed.
///
/// ### Example
/// ```swift
/// class ProfilePackM: EZSUIPackM {
///     var viewModel: ViewModel
///     @MainActor class ViewModel: ObservableObject {
///         @Published var name = ""
///     }
///
///     weak let inputI: InputIProtocol?
///     @MainActor protocol InputIProtocol: AnyObject {
///         func loadProfile()
///     }
///
///     weak let inputV: InputVProtocol?
///     @MainActor protocol InputVProtocol: AnyObject {}
///
///     init(inputI: InputI, inputV: InputV) {
///         self.inputI = inputI
///         self.inputV = inputV
///         self.viewModel = .init()
///     }
/// }
/// ```
///
/// - Note: Use `EZSUIPackM` (which is `EZSUIPackMediatorProtocol & EZSUIPackMediator`)
///   as your base type.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public protocol EZSUIPackMediatorProtocol: EZIMVPackMediatorProtocol {}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackMediatorProtocol where ViewModel == Void {
    /// Default implementation when `ViewModel` is `Void` (no shared state needed).
    public var viewModel: ViewModel {
        get { () }
        set {}
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackMediatorProtocol {
    /// The SwiftUI access object type for views.
    public typealias AccessSV = EZSUIPackAccessV<Self, AccessMapV>

    /// Creates the SwiftUI access object for views. Shadows the base
    /// `accessV` factory for SwiftUI mediators, so the call-site declaration
    /// stays identical to the UIKit flavor:
    /// ```swift
    /// let access = MyPackM.accessV
    /// ```
    /// Being a `DynamicProperty`, the returned access registers the owning
    /// view as a SwiftUI dependency of the view model.
    public static var accessV: AccessSV { .init(accessMap: accessMapV) }
}

/// Base class for SwiftUI mediators.
///
/// Inherits from `EZIMVPackMediator`. Use `EZSUIPackM` as the base type for your mediators.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
open class EZSUIPackMediator: EZIMVPackMediator {}

/// The primary type for creating SwiftUI mediators in the IMV architecture.
///
/// `EZSUIPackM` is a type alias that combines `EZSUIPackMediatorProtocol` and `EZSUIPackMediator`.
/// This is the **recommended base type** for all SwiftUI mediator implementations.
///
/// ### Example
/// ```swift
/// class MyPackM: EZSUIPackM {
///     var viewModel: ViewModel
///     @MainActor class ViewModel: ObservableObject { }
///
///     weak let inputI: InputIProtocol?
///     @MainActor protocol InputIProtocol: AnyObject { }
///
///     weak let inputV: InputVProtocol?
///     @MainActor protocol InputVProtocol: AnyObject { }
///
///     init(inputI: InputI, inputV: InputV) {
///         self.inputI = inputI
///         self.inputV = inputV
///         self.viewModel = .init()
///     }
/// }
/// ```
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZSUIPackM = EZSUIPackMediatorProtocol & EZSUIPackMediator
#endif
