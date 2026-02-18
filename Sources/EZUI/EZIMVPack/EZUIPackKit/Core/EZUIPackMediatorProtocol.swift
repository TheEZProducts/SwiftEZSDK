//
//  EZUIPackMediatorProtocol.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

/// Base protocol for mediators in the IMV architecture.
///
/// Provides access to the pack bridge. Typically you should use `EZUIPackMediatorProtocol`
/// which adds view model, input interfaces, and access maps.
@MainActor
public protocol EZUIPackBaseMediatorProtocol: AnyObject {
    /// The bridge that connects this mediator to its pack.
    ///
    /// Used internally to maintain the relationship between mediator, pack, and components.
    var packBridge: EZUIPackBridge { get set }
}

/// Protocol for mediators in the IMV architecture pattern.
///
/// A mediator manages communication and shared state between the interactor and view:
/// - **ViewModel**: Shared state that both interactor and view can read/write
/// - **InputI**: Protocol defining actions the interactor can perform (implemented by the interactor)
/// - **InputV**: Protocol defining actions the view can perform (implemented by the view)
/// - **Access maps**: Control what parts of the mediator are accessible to interactor/view
///
/// ### Example: Basic mediator implementation
/// ```swift
/// class ProfilePackM: EZUIPackM {
///     var viewModel: ViewModel
///     @MainActor struct ViewModel {
///         var profile: Profile?
///         var isLoading = false
///     }
///
///     weak let inputI: InputIProtocol?
///     @MainActor protocol InputIProtocol: AnyObject {
///         func loadProfile()
///         func editProfile()
///     }
///
///     weak let inputV: InputVProtocol?
///     @MainActor protocol InputVProtocol: AnyObject {
///         func showError(message: String)
///         func refreshUI()
///     }
///
///     init(inputI: InputI, inputV: InputV) {
///         self.inputI = inputI
///         self.inputV = inputV
///         self.viewModel = .init()
///     }
/// }
/// ```
///
/// - Note: Use `EZUIPackM` (which is `EZUIPackMediatorProtocol & EZUIPackMediator`) as your base class.

@MainActor
public protocol EZUIPackMediatorProtocol: EZIMVPackMediatorProtocol, EZUIPackBaseMediatorProtocol {}



extension EZUIPackMediatorProtocol {
    /// Access to the parent pack's shared storage, if available.
    ///
    /// This allows child packs to access data from their parent pack's interactor.
    /// Returns an empty storage if no parent is available.
    ///
    /// ### Example
    /// ```swift
    /// func didInitialize() {
    ///     if let parentData = parentShared.get(key: .someKey) {
    ///         // Use parent data
    ///     }
    /// }
    /// ```
    public var parentShared: EZSharedStorage {
        packBridge.pack?.interactor?.ezParentShared ?? .init()
    }
}


extension EZUIPackMediatorProtocol where ViewModel == Void {
    /// Default implementation when `ViewModel` is `Void`.
    ///
    /// Provides a no-op getter and setter for view model when no state is needed.
    public var viewModel: ViewModel {
        set {}
        get { () }
    }
}


/// Base class for mediators in the IMV architecture.
///
/// Provides the `packBridge` property that connects the mediator to its pack.
/// Use this as your base class when implementing `EZUIPackMediatorProtocol`.
///
/// ### Example
/// ```swift
/// class MyPackM: EZUIPackMediator, EZUIPackMediatorProtocol {
///     // ... implement protocol requirements
/// }
/// ```
@MainActor
open class EZUIPackMediator: EZIMVPackMediator, EZUIPackBaseMediatorProtocol {
    /// The bridge that connects this mediator to its pack.
    ///
    /// Used internally to maintain the relationship between mediator, pack, and components.
    public var packBridge = EZUIPackBridge()
}

/// The primary type for creating mediators in the IMV architecture.
///
/// `EZUIPackM` is a type alias that combines `EZUIPackMediatorProtocol` and `EZUIPackMediator`,
/// providing everything you need to create a mediator. This is the **recommended base type**
/// for all your mediator implementations.
///
/// A mediator is the central component that:
/// - **Manages shared state** via the `viewModel` property
/// - **Defines communication interfaces** via `InputI` (from interactor) and `InputV` (from view)
/// - **Coordinates between interactor and view** without them directly referencing each other
///
/// ## Structure
///
/// Every mediator must define:
/// 1. **ViewModel**: A struct containing shared state (can be `Void` if no state is needed)
/// 2. **InputI**: The interactor's action interface (protocol or struct with closures)
/// 3. **InputV**: The view's action interface (protocol or struct with closures)
/// 4. **Initializer**: Connects the interactor and view via their action interfaces
///
/// ## InputI and InputV: Protocols vs Structs
///
/// The `InputI` and `InputV` types can be either:
/// - **Protocols** (with `weak` references): Best for UIKit views and interactors (classes)
/// - **Structs with closures**: Best for SwiftUI views (structs) that can't be weak references
///
/// ## Example: Mediator with protocol-based interfaces (UIKit)
///
/// ```swift
/// class ProfilePackM: EZUIPackM {
///     // 1. Define the view model (shared state)
///     var viewModel: ViewModel
///     @MainActor struct ViewModel {
///         var profile: Profile?
///         var isLoading = false
///         var errorMessage: String?
///     }
///
///     // 2. Define the interactor's action interface as a protocol
///     weak let inputI: InputIProtocol?
///     @MainActor protocol InputIProtocol: AnyObject {
///         func loadProfile()
///         func editProfile()
///         func deleteProfile()
///     }
///
///     // 3. Define the view's action interface as a protocol
///     weak let inputV: InputVProtocol?
///     @MainActor protocol InputVProtocol: AnyObject {
///         func showError(message: String)
///         func refreshUI()
///         func navigateToEditScreen()
///     }
///
///     // 4. Initialize with inputs from interactor and view
///     init(inputI: InputI, inputV: InputV) {
///         self.inputI = inputI
///         self.inputV = inputV
///         self.viewModel = .init()
///     }
/// }
/// ```
///
/// ## Example: Mixed approach (protocol for interactor, struct for SwiftUI view)
///
/// ```swift
/// class ProfilePackM: EZUIPackM {
///     var viewModel: ViewModel
///     @MainActor struct ViewModel { }
///
///     // Protocol for UIKit interactor (class)
///     weak let inputI: InputIProtocol?
///     @MainActor protocol InputIProtocol: AnyObject {
///         func loadProfile()
///     }
///
///     // Struct for SwiftUI view (struct)
///     let inputV: InputV
///     @MainActor struct InputV {
///         var showError: (String) -> Void
///     }
///
///     init(inputI: InputI, inputV: InputV) {
///         self.inputI = inputI
///         self.inputV = inputV
///         self.viewModel = .init()
///     }
/// }
/// ```
///
/// ## Usage in Interactor and View
///
/// ### With Protocol Interfaces (UIKit)
///
/// ```swift
/// // In Interactor:
/// class ProfilePackI: EZUIPackI {
///     let access = ProfilePackM.accessI
///
///     func makeInput() -> Mediator.InputI { self }
/// }
///
/// extension ProfilePackI: ProfilePackM.InputIProtocol {
///     func loadProfile() { /* ... */ }
///     func editProfile() { /* ... */ }
/// }
///
/// // In UIKit View:
/// class ProfileIOSV: EZUIPackV {
///     let access = ProfilePackM.accessV
///
///     func makeInput() -> Mediator.InputV { self }
/// }
///
/// extension ProfileIOSV: ProfilePackM.InputVProtocol {
///     func showError(message: String) { /* ... */ }
///     func refreshUI() { /* ... */ }
/// }
/// ```
///
/// ### With Struct Interfaces (SwiftUI)
///
/// ```swift
/// // In SwiftUI View:
/// struct ProfileIOSV: View, EZUIPackSViewProtocol {
///     let access = ProfilePackM.accessV
///
///     func makeInput() -> Mediator.InputV {
///         .init(
///             showError: { message in
///                 // Show error
///             },
///             refreshUI: {
///                 // Refresh UI
///             }
///         )
///     }
///
///     var body: some View {
///         // SwiftUI content
///     }
/// }
/// ```
///
/// ## Example: Minimal mediator (no state, no actions)
///
/// ```swift
/// class SimplePackM: EZUIPackM {
///     var viewModel: ViewModel
///     @MainActor struct ViewModel { }
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
///
/// - Note: Always use `EZUIPackM` as your base type. It provides the necessary infrastructure
///   (`packBridge`, access maps, etc.) that the IMV architecture requires.
/// - Important: When using protocols, they must be marked with `@MainActor` and conform to
///   `AnyObject` (for weak references). When using structs, they should also be marked with
///   `@MainActor` and contain closures that capture the necessary context.

public typealias EZUIPackM = EZUIPackMediatorProtocol & EZUIPackMediator

#endif
