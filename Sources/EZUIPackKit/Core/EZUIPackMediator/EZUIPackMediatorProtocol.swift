//
//  EZUIPackM.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

import EZHelpersKit

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
///     required init(contextI: BaseContextI, contextV: BaseContextV) {
///         viewModel = contextI.viewModel
///         inputI = contextI.actions
///         inputV = contextV.actions
///     }
/// }
/// ```
///
/// - Note: Use `EZUIPackM` (which is `EZUIPackMediatorProtocol & EZUIPackMediator`) as your base class.
@MainActor
public protocol EZUIPackMediatorProtocol: EZUIPackBaseMediatorProtocol {
    //MARK: - Required Objects
    /// The type of view model that holds shared state between interactor and view.
    associatedtype ViewModel
    
    /// The view model instance holding shared state.
    ///
    /// Both interactor and view can read and write to this property to share state.
    var viewModel: ViewModel { get set }
    
    /// The type of input interface from the interactor.
    ///
    /// Typically a protocol (like `InputIProtocol`) that the interactor implements.
    associatedtype InputI
    
    /// The interactor's action interface instance.
    var inputI: InputI { get }
    
    /// The type of input interface from the view.
    ///
    /// Typically a protocol (like `InputVProtocol`) that the view implements.
    associatedtype InputV
    
    /// The view's action interface instance.
    var inputV: InputV { get }
    
    //MARK: - Access
    /// Type alias for the access object used by interactors.
    typealias AccessI = EZMediatorAccessI<Self, AccessMapI>
    
    /// Type alias for the access object used by views.
    typealias AccessV = EZMediatorAccessV<Self, AccessMapV>
    
    /// The type of access map for interactors.
    ///
    /// Controls what parts of the mediator are accessible to the interactor.
    /// Use `()` for default access (all properties via access object).
    associatedtype AccessMapI
    
    /// The access map instance for interactors.
    ///
    /// Defines what parts of the mediator the interactor can access.
    /// Defaults to `()` which provides standard access.
    static var accessMapI: AccessMapI { get }
    
    /// The type of access map for views.
    ///
    /// Controls what parts of the mediator are accessible to the view.
    /// Use `()` for default access (all properties via access object).
    associatedtype AccessMapV
    
    /// The access map instance for views.
    ///
    /// Defines what parts of the mediator the view can access.
    /// Defaults to `()` which provides standard access.
    static var accessMapV: AccessMapV { get }
    
    /// Called after the mediator is created and all components are connected.
    ///
    /// Override this to perform initialization that requires all components to be set up.
    func didInitialize()
    
    //MARK: - Init
    /// Type alias for the base context type from interactor.
    typealias BaseContextI = EZUIPackMediatorContextI<Self>
    
    /// The type of context passed from the interactor during initialization.
    ///
    /// Defaults to `BaseContextI`. Override if you need a custom context type.
    associatedtype ContextI = BaseContextI
    
    /// Type alias for the base context type from view.
    typealias BaseContextV = EZUIPackMediatorContextV<Self>
    
    /// The type of context passed from the view during initialization.
    ///
    /// Defaults to `BaseContextV`. Override if you need a custom context type.
    associatedtype ContextV = BaseContextV
    
    /// Creates a mediator with contexts from both interactor and view.
    ///
    /// - Parameters:
    ///   - contextI: Context from the interactor containing actions and initial view model.
    ///   - contextV: Context from the view containing actions.
    ///
    /// ### Example
    /// ```swift
    /// required init(contextI: BaseContextI, contextV: BaseContextV) {
    ///     viewModel = contextI.viewModel
    ///     inputI = contextI.actions
    ///     inputV = contextV.actions
    /// }
    /// ```
    init(contextI: ContextI, contextV: ContextV)
}


extension EZUIPackMediatorProtocol {
    /// Access to the parent pack's shared storage, if available.
    ///
    /// This allows child packs to access data from their parent pack's interactor.
    /// Returns an empty storage if no parent is available.
    ///
    /// ### Example
    /// ```swift
    /// func didInitialize() {
    ///     if let parentData = parentShered.get(key: .someKey) {
    ///         // Use parent data
    ///     }
    /// }
    /// ```
    public var parentShered: EZSharedStorage {
        packBridge.pack?.interactor?.ezParentShered ?? .init()
    }
    
    /// Called after the mediator is created and all components are connected.
    ///
    /// Override this to perform initialization that requires all components to be set up.
    public func didInitialize() {}
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

extension EZUIPackMediatorProtocol where InputI == Void {
    /// Default implementation when `InputI` is `Void`.
    ///
    /// Returns `()` when no interactor actions are needed.
    public var inputI: InputI { () }
}

extension EZUIPackMediatorProtocol where InputV == Void {
    /// Default implementation when `InputV` is `Void`.
    ///
    /// Returns `()` when no view actions are needed.
    public var inputV: InputV { () }
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
open class EZUIPackMediator: EZUIPackBaseMediatorProtocol {
    /// The bridge that connects this mediator to its pack.
    ///
    /// Used internally to maintain the relationship between mediator, pack, and components.
    public var packBridge = EZUIPackBridge()
    
    /// Creates a new mediator instance.
    public init(){}
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
///     // 4. Initialize with contexts from interactor and view
///     required init(contextI: BaseContextI, contextV: BaseContextV) {
///         viewModel = contextI.viewModel
///         inputI = contextI.actions
///         inputV = contextV.actions
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
///     required init(contextI: BaseContextI, contextV: BaseContextV) {
///         viewModel = contextI.viewModel
///         inputI = contextI.actions
///         inputV = contextV.actions
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
///     func makeContext() -> Mediator.ContextI {
///         .init(actions: self, viewModel: .init())
///     }
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
///     func makeContext() -> Mediator.ContextV {
///         .init(actions: self)
///     }
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
///     func makeContext() -> Mediator.ContextV {
///         .init(actions: .init(
///             showError: { message in
///                 // Show error
///             },
///             refreshUI: {
///                 // Refresh UI
///             }
///         ))
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
///     required init(contextI: BaseContextI, contextV: BaseContextV) {
///         viewModel = contextI.viewModel
///         inputI = contextI.actions
///         inputV = contextV.actions
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
