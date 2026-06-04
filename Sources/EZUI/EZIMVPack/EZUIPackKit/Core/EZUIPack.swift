//
//  EZUIPack.swift
//  EZSDK
//
//  Created by Александр Сенин on 24.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// The core protocol for the IMV (Interactor-Mediator-View) architecture pattern.
///
/// `EZUIPackProtocol` defines the contract for a UI component that coordinates between three main parts:
/// - **Interactor**: Handles business logic and user actions (typically a `UIViewController`)
/// - **Mediator**: Manages communication between Interactor and View, holds shared state (`viewModel`)
/// - **View**: Handles UI presentation and user interactions
///
/// The pack lifecycle follows UIKit's view controller lifecycle, with additional hooks for initialization,
/// creation, opening/closing animations, and installation.
///
/// ### Example: Basic usage
/// ```swift
/// class MyPackI: EZUIPackI {
///     let access = MyPackM.accessI
///
///     func makeInput() -> Mediator.InputI { self }
/// }
///
/// class MyPackM: EZUIPackM {
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
///
/// class MyPackV: EZUIPackPlatformsV<MyPackM> {
///     override var iOS: (any EZUIPackViewProtocol<MyPackM>)? {
///         MyPackIOSV()
///     }
/// }
///
/// // Create via EZPackMaker:
/// enum MyPack {
///     @MainActor
///     static func make() -> MyPackI {
///         EZPackMaker.make(
///             interactor: { MyPackI() },
///             mediator: { inputI, inputV in MyPackM(inputI: inputI, inputV: inputV) },
///             view: { MyPackV() }
///         )
///     }
/// }
///
/// let interactor = MyPack.make()
/// ```
@MainActor
public protocol EZUIPackProtocol: AnyObject {
    /// The type of interactor that handles business logic for this pack.
    associatedtype Interactor: EZUIPackInteractorProtocol where Interactor.Mediator == Mediator
    
    /// The type of mediator that manages communication and state for this pack.
    associatedtype Mediator: EZUIPackMediatorProtocol
    
    /// The type of view that handles UI presentation for this pack.
    associatedtype View: EZUIPackViewProtocol where View.Mediator == Mediator
    
    /// The interactor connected to this pack, if any.
    var interactor: Interactor? { get }
    
    /// The mediator connected to this pack, if any.
    var mediator: Mediator? { get }
    
    /// The view component managed by this pack.
    var view: View { get }
    
    /// Optional transition controller for custom view controller transitions.
    var transitionController: EZTransitionControllerProtocol? { get set }
    
    /// Loads and returns the view for this pack.
    ///
    /// - Parameter frame: The initial frame for the view.
    /// - Returns: A configured `UIView` ready for display.
    func loadView(frame: CGRect) -> UIView
    
    /// Called when the pack's view has been loaded.
    ///
    /// Forwards to the view's `viewDidLoad()` method.
    func viewDidLoad()
    
    /// Called when the pack is added to or removed from a parent view controller.
    ///
    /// - Parameter parent: The parent view controller, or `nil` if removed.
    func didMove(toParent parent: UIViewController?)
    
    /// Called when the pack's view is about to appear.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    func viewWillAppear(_ animated: Bool)
    
    /// Called during the appearance transition (iOS 13.0+).
    ///
    /// - Parameter animated: Whether the appearance is animated.
    @available(iOS 13.0, tvOS 13.0, *)
    func viewIsAppearing(_ animated: Bool)
    
    /// Called when the pack's view layout has changed.
    ///
    /// Triggers `didInstall()` on interactor and view after the first layout.
    func viewDidLayoutSubviews()
    
    /// Called when the pack's view has fully appeared.
    ///
    /// - Parameter animated: Whether the appearance was animated.
    func viewDidAppear(_ animated: Bool)

    /// Called when the pack's view is about to disappear.
    ///
    /// - Parameter animated: Whether the disappearance is animated.
    func viewWillDisappear(_ animated: Bool)
    
    /// Called when the pack's view has fully disappeared.
    ///
    /// - Parameter animated: Whether the disappearance was animated.
    func viewDidDisappear(_ animated: Bool)
    
    /// Sets up the pack by connecting the interactor and mediator.
    ///
    /// This method connects all components and calls `didInitialize()`
    /// on mediator, interactor, and view.
    ///
    /// - Parameters:
    ///   - interactor: The interactor to connect to this pack.
    ///   - mediator: The mediator to connect to this pack.
    func setup(interactor: Interactor, mediator: Mediator)
    
    /// Creates a pack with the given view.
    ///
    /// - Parameter view: The view component that will be managed by this pack.
    init(view: View)
}

/// The concrete implementation of `EZUIPackProtocol` that manages the IMV architecture lifecycle.
///
/// `EZUIPack` coordinates the three components of the IMV pattern:
/// - `I` (Interactor): Handles business logic, typically a `UIViewController` subclass
/// - `M` (Mediator): Manages state and communication between Interactor and View
/// - `V` (View): Handles UI presentation
///
/// The pack automatically manages the lifecycle:
/// 1. **Initialization**: `setup(interactor:mediator:)` connects all components
/// 2. **Creation**: `start()` → `create()` → `didCreate()` when the pack first appears
/// 3. **Opening**: `willOpen()` → `animateOpen()` → `didOpen()` when becoming visible
/// 4. **Installation**: `didInstall()` after layout completes
/// 5. **Closing**: `willClose()` → `animateClose()` → `didClose()` when disappearing
///
/// ### Example: Complete pack implementation
/// ```swift
/// // 1. Define the Interactor
/// class ProfilePackI: EZUIPackI {
///     let access = ProfilePackM.accessI
///
///     func makeInput() -> Mediator.InputI { self }
/// }
///
/// // 2. Define the Mediator
/// class ProfilePackM: EZUIPackM {
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
///
/// // 3. Define the View
/// class ProfilePackV: EZUIPackPlatformsV<ProfilePackM> {
///     override var iOS: (any EZUIPackViewProtocol<ProfilePackM>)? {
///         ProfileIOSV()
///     }
/// }
///
/// // 4. Create the pack via EZPackMaker
/// enum ProfilePack {
///     @MainActor
///     static func make() -> ProfilePackI {
///         EZPackMaker.make(
///             interactor: { ProfilePackI() },
///             mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
///             view: { ProfilePackV() }
///         )
///     }
/// }
///
/// // 5. Use the pack
/// let interactor = ProfilePack.make()
/// navigationController.pushViewController(interactor, animated: true)
/// ```
///
/// - Note: Use `EZPackMaker.make(interactor:mediator:view:)` to create packs,
///   as it handles the initialization sequence correctly.
@MainActor
open class EZUIPack<
    I: EZUIPackInteractorProtocol,
    M: EZUIPackMediatorProtocol,
    V: EZUIPackViewProtocol
>: EZUIPackProtocol where I.Mediator == M, V.Mediator == M {
    /// The interactor connected to this pack.
    ///
    /// Set to `nil` initially and assigned during `setup(interactor:mediator:)`.
    /// Weak reference to avoid retain cycles.
    public private(set) weak var interactor: I?
    
    /// The mediator connected to this pack.
    ///
    /// Set to `nil` initially and assigned during `setup(interactor:mediator:)`.
    public private(set) var mediator: M?
    
    /// The view component managed by this pack.
    ///
    /// Set during initialization and remains constant for the pack's lifetime.
    public let view: V
    
    /// Optional transition controller for custom view controller transitions.
    ///
    /// Set this to customize how this pack transitions when presented or dismissed.
    public var transitionController: (any EZTransitionControllerProtocol)?
    
    /// The parent view controller that contains this pack, if any.
    ///
    /// Set automatically when the pack is added to or removed from a parent.
    public weak var parentController: UIViewController?
    
    /// Whether the pack has been started (creation lifecycle has begun).
    ///
    /// Set to `true` after `start()`, `create()`, and `didCreate()` have been called.
    public var isStarted = false
    
    /// Whether the pack is about to appear.
    ///
    /// Used internally to coordinate the opening lifecycle with layout.
    public var willAppear: Bool = false
    private var openAction: (() -> Void)?
    
    /// Creates a pack with the given view.
    ///
    /// - Parameter view: The view component that will be managed by this pack.
    /// - Note: Typically you should use `EZPackMaker.make(interactor:mediator:view:)` instead of
    ///   calling this initializer directly.
    public required init(view: V) {
        self.view = view
    }
    
    /// Sets up the pack by connecting the interactor, mediator, and initializing all components.
    ///
    /// This method:
    /// 1. Connects the mediator to the pack bridge
    /// 2. Sets up access objects for both interactor and view
    /// 3. Calls `didInitialize()` on mediator, interactor, and view
    ///
    /// - Parameters:
    ///   - interactor: The interactor to connect to this pack.
    ///   - mediator: The mediator to connect to this pack.
    /// - Note: This is typically called automatically by `EZPackMaker.make(interactor:mediator:view:)`.
    open func setup(interactor: I, mediator: M) {
        mediator.packBridge.pack = self
        interactor.access.setMediator(mediator)
        view.access.setMediator(mediator)

        self.interactor = interactor
        self.mediator = mediator

        mediator.didInitialize()
        interactor.didInitialize()
        view.didInitialize()
    }
    
    /// Loads and configures the view for the pack.
    ///
    /// Creates a `UIView` from the pack's view component, sets up autoresizing masks,
    /// and configures it for display.
    ///
    /// - Parameter frame: The initial frame for the view.
    /// - Returns: A configured `UIView` ready for display.
    open func loadView(frame: CGRect) -> UIView {
        let uiView = self.view.getView()
        uiView.frame = frame
        uiView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        uiView.layer.masksToBounds = true
        return uiView
    }
    
    /// Called when the pack's view has been loaded.
    ///
    /// Forwards to the view's `viewDidLoad()` method. Override to perform additional setup.
    open func viewDidLoad() {
        view.viewDidLoad()
    }
    
    /// Called when the pack is added to or removed from a parent view controller.
    ///
    /// Updates `parentController` and forwards to the view if needed.
    ///
    /// - Parameter parent: The parent view controller, or `nil` if removed.
    open func didMove(toParent parent: UIViewController?){
        self.parentController = parent
    }
    
    /// Called when the pack's view is about to appear.
    ///
    /// Resizes to preferred content size if needed, marks that appearance is pending,
    /// and triggers the opening lifecycle via `open()`.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    open func viewWillAppear(_ animated: Bool){
        view.viewWillAppear(animated)
        
        resizeToPreferredContentSize()
        willAppear = true
        
        performWithTransitionCoordinator{[weak self] in
            self?.open()
        }
    }
    
    /// Opens the pack, triggering the creation and opening lifecycle if needed.
    ///
    /// This method:
    /// - Calls `start()`, `create()`, and `didCreate()` if the pack hasn't started yet
    /// - Calls `willOpen()` on both interactor and view
    /// - Triggers `animateOpen()` on the view
    ///
    /// Called automatically during `viewWillAppear(_:)` lifecycle.
    open func open(){
        UIView.performWithoutAnimation {
            if !isStarted {
                interactor?.start()
                view.create()
                interactor?.didCreate()
                isStarted = true
            }
            
            interactor?.willOpen()
            view.willOpen()
        }
    
        view.animateOpen()
    }
    
    /// Called during the appearance transition (iOS 13.0+).
    ///
    /// Forwards to the view's `viewIsAppearing(_:)` method.
    ///
    /// - Parameter animated: Whether the appearance is animated.
    @available(iOS 13.0, tvOS 13.0, *)
    open func viewIsAppearing(_ animated: Bool) {
        view.viewIsAppearing(animated)
    }
    
    /// Called when the pack's view layout has changed.
    ///
    /// After the first layout (when `willAppear` is true), this triggers `didInstall()`
    /// on both interactor and view, and executes any pending opening actions.
    open func viewDidLayoutSubviews(){
        guard willAppear else { return }
        willAppear = false
        openAction?()
        openAction = nil
        interactor?.didInstall()
        view.didInstall()
    }
    
    /// Called when the pack's view has fully appeared.
    ///
    /// Forwards to the view's `viewDidAppear(_:)` method, then calls `didOpen()`
    /// on both interactor and view.
    ///
    /// - Parameter animated: Whether the appearance was animated.
    open func viewDidAppear(_ animated: Bool) {
        view.viewDidAppear(animated)
        interactor?.didOpen()
        view.didOpen()
    }

    /// Called when the pack's view is about to disappear.
    ///
    /// Forwards to the view's `viewWillDisappear(_:)` method, calls `willClose()`
    /// on both interactor and view, and triggers closing animations.
    ///
    /// - Parameter animated: Whether the disappearance is animated.
    open func viewWillDisappear(_ animated: Bool) {
        view.viewWillDisappear(animated)
        interactor?.willClose()
        view.willClose()
        
        performWithTransitionCoordinator{[view] in
            view.animateClose()
        }
    }

    /// Called when the pack's view has fully disappeared.
    ///
    /// Forwards to the view's `viewDidDisappear(_:)` method, then calls `didClose()`
    /// on both interactor and view.
    ///
    /// - Parameter animated: Whether the disappearance was animated.
    open func viewDidDisappear(_ animated: Bool) {
        view.viewDidDisappear(animated)
        interactor?.didClose()
        view.didClose()
    }
    
    private func resizeToPreferredContentSize(){
        if
            let size = interactor?.preferredContentSize,
            size != .zero
        {
            interactor?.view.frame.size = size
            interactor?.view.layoutIfNeeded()
        }
    }
    
    private func performWithTransitionCoordinator(action: @escaping () -> ()) {
        var animated = false
        if
            let transitionCoordinator = interactor?.firstTransitionCoordinator ??
                parentController?.firstTransitionCoordinator,
            transitionCoordinator.transitionDuration > 0
        {
            
            animated = transitionCoordinator.animate {_ in
                action()
            }
        }
        
        if !animated {
            openAction = action
            interactor?.view.setNeedsLayout()
        }
    }
}


// MARK: - EZUIPack + make()

extension EZUIPack {
    /// Creates a fully initialized pack using `EZPackMaker`.
    ///
    /// A convenience shortcut so that a typealias can serve as the pack's namespace:
    /// ```swift
    /// typealias ProfilePack = EZUIPack<ProfilePackI, ProfilePackM, ProfilePackV>
    ///
    /// let interactor = ProfilePack.make(
    ///     interactor: { ProfilePackI() },
    ///     mediator: { inputI, inputV, context in ProfilePackM(inputI: inputI, inputV: inputV) },
    ///     view: { ProfilePackV() }
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - makeI: A closure that creates the interactor. The pack is available via `EZPackMaker.getPack()`.
    ///   - makeM: A closure that creates the mediator, receiving inputs from interactor and view,
    ///     plus optional context from the interactor.
    ///   - makeV: A closure that creates the view.
    /// - Returns: The fully initialized interactor ready to use.
    public static func make(
        interactor makeI: () -> I,
        mediator makeM: (M.InputI, M.InputV, I.Context) -> M,
        view makeV: () -> V
    ) -> I {
        EZPackMaker.make(interactor: makeI, mediator: makeM, view: makeV)
    }
}

extension EZUIPack where I.Context == Void {
    /// Creates a fully initialized pack using `EZPackMaker`.
    ///
    /// Convenience overload for interactors with `Context == Void`.
    ///
    /// ```swift
    /// typealias ProfilePack = EZUIPack<ProfilePackI, ProfilePackM, ProfilePackV>
    ///
    /// let interactor = ProfilePack.make(
    ///     interactor: { ProfilePackI() },
    ///     mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
    ///     view: { ProfilePackV() }
    /// )
    /// ```
    ///
    /// - Parameters:
    ///   - makeI: A closure that creates the interactor. The pack is available via `EZPackMaker.getPack()`.
    ///   - makeM: A closure that creates the mediator, receiving inputs from interactor and view.
    ///   - makeV: A closure that creates the view.
    /// - Returns: The fully initialized interactor ready to use.
    public static func make(
        interactor makeI: () -> I,
        mediator makeM: (M.InputI, M.InputV) -> M,
        view makeV: () -> V
    ) -> I {
        EZPackMaker.make(interactor: makeI, mediator: makeM, view: makeV)
    }
}


/// A factory for creating packs with proper initialization order.
///
/// `EZPackMaker` manages the creation process to ensure that:
/// - The view and pack are created before the interactor
/// - The interactor can access the pack during initialization via `EZPackMaker.getPack()`
/// - All components are properly connected before use
///
/// ### Example: Creating a pack
/// ```swift
/// enum ProfilePack {
///     @MainActor
///     static func make() -> ProfilePackI {
///         EZPackMaker.make(
///             interactor: { ProfilePackI() },
///             mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
///             view: { ProfilePackV() }
///         )
///     }
/// }
/// ```
///
/// ### Example: Custom initialization with parameters
/// ```swift
/// enum ProfilePack {
///     @MainActor
///     static func make(userId: String, theme: Theme) -> ProfilePackI {
///         EZPackMaker.make(
///             interactor: { ProfilePackI(userId: userId) },
///             mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
///             view: { ProfileIOSV(theme: theme) }
///         )
///     }
/// }
/// ```
@MainActor
public final class EZPackMaker: Sendable {
    private static var currentSession = [(any MakeSessionProtocol)]()

    /// Creates a pack with three closures for interactor, mediator, and view.
    ///
    /// This method manages the creation order: **view → pack → interactor → mediator → setup**.
    /// The pack is available via `EZPackMaker.getPack()` during interactor initialization.
    ///
    /// - Parameters:
    ///   - makeI: A closure that creates the interactor. The pack is available via `EZPackMaker.getPack()`.
    ///   - makeM: A closure that creates the mediator, receiving inputs from interactor and view,
    ///     plus optional context from the interactor.
    ///   - makeV: A closure that creates the view.
    /// - Returns: The fully initialized interactor ready to use.
    public static func make<
        I: EZUIPackInteractorProtocol,
        M: EZUIPackMediatorProtocol,
        V: EZUIPackViewProtocol
    >(
        interactor makeI: () -> I,
        mediator makeM: (M.InputI, M.InputV, I.Context) -> M,
        view makeV: () -> V
    ) -> I where I.Mediator == M, V.Mediator == M {
        let view = makeV()
        let pack = EZUIPack<I, M, V>(view: view)

        currentSession.append(MakeSession(pack: pack))
        defer { currentSession.removeLast() }

        let interactor = makeI()
        let mediator = makeM(interactor.makeInput(), view.makeInput(), interactor.makeContext())
        pack.setup(interactor: interactor, mediator: mediator)

        return interactor
    }

    /// Creates a pack with three closures for interactor, mediator, and view.
    ///
    /// Convenience overload for interactors with `Context == Void`. The mediator closure
    /// receives only `InputI` and `InputV`.
    ///
    /// - Parameters:
    ///   - makeI: A closure that creates the interactor. The pack is available via `EZPackMaker.getPack()`.
    ///   - makeM: A closure that creates the mediator, receiving inputs from interactor and view.
    ///   - makeV: A closure that creates the view.
    /// - Returns: The fully initialized interactor ready to use.
    public static func make<
        I: EZUIPackInteractorProtocol,
        M: EZUIPackMediatorProtocol,
        V: EZUIPackViewProtocol
    >(
        interactor makeI: () -> I,
        mediator makeM: (M.InputI, M.InputV) -> M,
        view makeV: () -> V
    ) -> I where I.Mediator == M, V.Mediator == M, I.Context == Void {
        make(
            interactor: makeI,
            mediator: { inputI, inputV, _ in makeM(inputI, inputV) },
            view: makeV
        )
    }

    private static func getCurrentSession() -> any MakeSessionProtocol {
        guard let currentSession = currentSession.last else { fatalError("Call EZPackMaker.make(...) first.") }
        return currentSession
    }

    /// Gets the current pack being created during the `make()` process.
    ///
    /// This allows interactors to access their pack during initialization.
    /// Only available within the `interactor` closure passed to `make()`.
    ///
    /// - Returns: The pack currently being created.
    /// - Important: This will crash if called outside of a `make()` call. Use only within
    ///   the interactor's initializer or setup code.
    ///
    /// ### Example
    /// ```swift
    /// class MyPackI: EZUIPackI {
    ///     init() {
    ///         let pack = EZPackMaker.getPack() // Access pack during init
    ///         // ...
    ///     }
    /// }
    /// ```
    public static func getPack() -> (any EZUIPackProtocol) {
        getCurrentSession().getPack()
    }

    @MainActor
    protocol MakeSessionProtocol {
        func getPack() -> (any EZUIPackProtocol)
    }

    @MainActor
    final class MakeSession: MakeSessionProtocol, Sendable {
        private let pack: any EZUIPackProtocol
        func getPack() -> any EZUIPackProtocol { pack }
        init(pack: any EZUIPackProtocol) { self.pack = pack }
    }
}

#endif
