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
/// Extends `EZPackMediatorBaseProtocol` with the requirement that `ViewModel` conforms
/// to `ObservableObject`, enabling automatic SwiftUI view updates when the view model changes.
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
public protocol EZSUIPackMediatorProtocol: EZPackMediatorBaseProtocol where ViewModel: ObservableObject {}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackMediatorProtocol where ViewModel == EZSUIPackVoidViewModel {
    /// Default implementation when `ViewModel` is `EZSUIPackVoidViewModel` (no shared state needed).
    public var viewModel: ViewModel {
        get { .shared }
        set {}
    }
}

/// A shared singleton `ObservableObject` used when a mediator has no view model state.
///
/// Use `EZSUIPackVoidViewModel` as the `ViewModel` type when no shared state is needed.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public final class EZSUIPackVoidViewModel: ObservableObject {
    public static let shared = EZSUIPackVoidViewModel()
    private init() {}
}

/// Base class for SwiftUI mediators.
///
/// Inherits from `EZPackMediator`. Use `EZSUIPackM` as the base type for your mediators.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
open class EZSUIPackMediator: EZPackMediator {}

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
