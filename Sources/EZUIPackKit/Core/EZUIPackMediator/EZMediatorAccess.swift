//
//  EZMediatorAccess.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

#if canImport(UIKit) && !os(watchOS)

import Foundation

import EZHelpersKit

class MediatorAccessContainer<Value> {
    private var value: Value?
    private let errorMessage: String
    
    func get() -> Value {
        guard let value else { fatalError(errorMessage) }
        return value
    }
    func set(_ value: Value) { self.value = value }
    
    init(value: Value? = nil, errorMessage: String) {
        self.value = value
        self.errorMessage = errorMessage
    }
}

/// Access object that provides the interactor with controlled access to the mediator.
///
/// `EZMediatorAccessI` allows the interactor to:
/// - Read and write the `viewModel`
/// - Read the `inputV` (view's action interface)
/// - Access additional mediator properties via the access map
///
/// The access is only available after `didInitialize()` has been called on the mediator.
///
/// ### Example
/// ```swift
/// class ProfilePackI: EZUIPackI {
///     let access = ProfilePackM.accessI
///     
///     func loadProfile() {
///         viewModel.isLoading = true
///         // ... load data
///         viewModel.profile = loadedProfile
///         viewModel.isLoading = false
///     }
/// }
/// ```
public class EZMediatorAccessI<Mediator: EZUIPackMediatorProtocol, AccessMap>: EZMappedAccess<Mediator, AccessMap> {
    private var container = MediatorAccessContainer<Mediator>(
        errorMessage: "Use the access only after the `didInitialize()` was called."
    )
    private var mediator: Mediator { container.get() }
    
    /// Access to the mediator's view model for reading and writing.
    ///
    /// Use this to read and modify the shared state between interactor and view.
    @MainActor
    public var viewModel: Mediator.ViewModel {
        get { mediator.viewModel }
        set { mediator.viewModel = newValue }
    }
    
    /// Access to the view's action interface.
    ///
    /// Use this to call methods defined in the mediator's `InputVProtocol` protocol.
    @MainActor
    public var inputV: Mediator.InputV {
        get { mediator.inputV }
    }
    
    /// Sets the mediator for this access object.
    ///
    /// Called automatically during pack setup. You typically don't need to call this manually.
    ///
    /// - Parameter mediator: The mediator to connect to this access object.
    public func setMediator(_ mediator: Mediator) { container.set(mediator) }

    init(_ mediator: Mediator? = nil, accessMap: AccessMap) {
        super.init({[container] in container.get() }, accessMap: accessMap)
        mediator.map { container.set($0) }
    }
}

/// Access object that provides the view with controlled access to the mediator.
///
/// `EZMediatorAccessV` allows the view to:
/// - Read and write the `viewModel`
/// - Read the `inputI` (interactor's action interface)
/// - Access the `packBridge` for advanced operations
/// - Access additional mediator properties via the access map
///
/// The access is only available after `didInitialize()` has been called on the mediator.
///
/// ### Example
/// ```swift
/// class ProfileIOSV: EZUIPackV {
///     let access = ProfilePackM.accessV
///     
///     func updateUI() {
///         if viewModel.isLoading {
///             showLoadingIndicator()
///         } else {
///             displayProfile(viewModel.profile)
///         }
///     }
///     
///     @objc func didTapEdit() {
///         inputI.editProfile()
///     }
/// }
/// ```
public class EZMediatorAccessV<Mediator: EZUIPackMediatorProtocol, AccessMap>: EZMappedAccess<Mediator, AccessMap> {
    private var container = MediatorAccessContainer<Mediator>(
        errorMessage: "Use the access only after the `didInitialize()` was called."
    )
    private var mediator: Mediator { container.get() }
    
    /// Sets the mediator for this access object.
    ///
    /// Called automatically during pack setup. You typically don't need to call this manually.
    ///
    /// - Parameter mediator: The mediator to connect to this access object.
    public func setMediator(_ mediator: Mediator) { container.set(mediator) }
    
    /// Access to the pack bridge.
    ///
    /// Use this for advanced operations that require access to the pack or interactor.
    @MainActor
    public var packBridge: EZUIPackBridge {
        get { mediator.packBridge }
    }
    
    /// Access to the mediator's view model for reading and writing.
    ///
    /// Use this to read and modify the shared state between interactor and view.
    @MainActor
    public var viewModel: Mediator.ViewModel {
        get { mediator.viewModel }
        set { mediator.viewModel = newValue }
    }
    
    /// Access to the interactor's action interface.
    ///
    /// Use this to call methods defined in the mediator's `InputIProtocol` protocol.
    @MainActor
    public var inputI: Mediator.InputI {
        get { mediator.inputI }
    }

    init(_ mediator: Mediator? = nil, accessMap: AccessMap) {
        super.init({[container] in container.get() }, accessMap: accessMap)
        mediator.map { container.set($0) }
    }
}

extension EZUIPackMediatorProtocol {
    /// Creates an access object for interactors to use.
    ///
    /// Use this in your interactor to get access to the mediator:
    /// ```swift
    /// let access = MyPackM.accessI
    /// ```
    public static var accessI: AccessI { .init(accessMap: accessMapI) }
    
    /// Creates an access object for views to use.
    ///
    /// Use this in your view to get access to the mediator:
    /// ```swift
    /// let access = MyPackM.accessV
    /// ```
    public static var accessV: AccessV { .init(accessMap: accessMapV) }
    
    static func rKey<Value>(
        _ keyPath: KeyPath<Self, Value>
    ) -> KeyPath<Self, Value> { keyPath }
    
    static func rwKey<Value>(
        _ keyPath: ReferenceWritableKeyPath<Self, Value>
    ) -> ReferenceWritableKeyPath<Self, Value> { keyPath }
}

extension EZUIPackMediatorProtocol where AccessMapI == () {
    /// Default implementation when `AccessMapI` is `Void`.
    ///
    /// Provides standard access to all mediator properties via the access object.
    public static var accessMapI: AccessMapI { () }
}

extension EZUIPackMediatorProtocol where AccessMapV == () {
    /// Default implementation when `AccessMapV` is `Void`.
    ///
    /// Provides standard access to all mediator properties via the access object.
    public static var accessMapV: AccessMapV { () }
}

#endif
