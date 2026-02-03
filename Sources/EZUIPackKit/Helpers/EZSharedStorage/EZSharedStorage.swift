//
//  EZSharedStorage.swift
//  EZSDK
//
//  Created by Александр Сенин on 23.02.2025.
//

import Foundation

/// Protocol for objects that can provide shared storage to child view controllers.
///
/// Implement this protocol to allow child view controllers to access data from their parent.
/// Works with any `UIViewController` that conforms to this protocol.
@MainActor
public protocol EZSharingProtocol {
    /// Shared storage that child view controllers can access via `ezParentShered` property.
    var shared: EZSharedStorage? { get }
}

/// A type-safe storage for sharing data between parent and child view controllers.
///
/// `EZSharedStorage` provides a dictionary-like interface using `EZSharedKey` for type-safe access.
/// Use this to pass data from a parent view controller (that conforms to `EZSharingProtocol`) to child view controllers.
///
/// ### Example: Using shared storage
/// ```swift
/// // 1. Define keys for the view controller's shared storage
/// extension EZSharedKeyChain<OnboardingViewController> {
///     var onboardingStatus: EZSharedKey<Self, OnboardingStatus> { .init(key: "OnboardingStatus") }
///     var onboardingActions: EZSharedKey<Self, OnboardingActions> { .init(key: "OnboardingActions") }
/// }
///
/// extension EZSharedKey {
///     static var onboardingChain: EZSharedKeyChain<OnboardingViewController> { .init() }
/// }
///
/// // 2. In parent view controller (any UIViewController that conforms to EZSharingProtocol):
/// class OnboardingViewController: UIViewController, EZSharingProtocol {
///     var shared: EZSharedStorage? {
///         .init([
///             .init(key: .onboardingChain.onboardingStatus, value: currentStatus),
///             .init(key: .onboardingChain.onboardingActions, value: actions)
///         ])
///     }
/// }
///
/// // 3. In child view controller:
/// class OnboardingStepViewController: UIViewController {
///     override func viewWillAppear(_ animated: Bool) {
///         super.viewWillAppear(animated)
///         if let status = ezParentShered[.onboardingChain.onboardingStatus] {
///             // Use parent's onboarding status
///         }
///         ezParentShered[.onboardingChain.onboardingActions]?.next()
///     }
/// }
/// ```
public struct EZSharedStorage {
    private var storage = [String: Any]()
    
    /// Accesses a value in the storage using a type-safe key.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: The value associated with the key, or `nil` if not found.
    ///
/// ### Example
/// ```swift
/// storage[.onboardingChain.onboardingStatus] = currentStatus
/// let status: OnboardingStatus? = storage[.onboardingChain.onboardingStatus]
/// ```
    public subscript<C, T>(_ key: EZSharedKey<C, T>) -> T? {
        set(value){ storage[key.key] = value }
        get{ storage[key.key] as? T }
    }
    
    /// Creates an empty shared storage.
    public init(){}
    
    /// Creates a shared storage from an array of containers.
    ///
    /// - Parameter controls: The containers to add to the storage.
    public init(_ controls: [EZSharedContainer]){ append(controls: controls) }
    
    /// Creates a shared storage with a single key-value pair.
    ///
    /// - Parameters:
    ///   - key: The key to store.
    ///   - value: The value to store.
    public init<C, T>(key: EZSharedKey<C, T>, value: T){ append(key: key, value: value) }
    
    /// Appends a key-value pair to the storage.
    ///
    /// - Parameters:
    ///   - key: The key to store.
    ///   - value: The value to store.
    public mutating func append<C, T>(key: EZSharedKey<C, T>, value: T){
        self[key] = value
    }
    
    /// Appends multiple containers to the storage.
    ///
    /// - Parameter controls: The containers to add.
    public mutating func append(controls: [EZSharedContainer]){
        controls.forEach { storage[$0.key.key] = $0.value }
    }
    
    /// Combines two shared storage instances.
    ///
    /// Values from `rhs` overwrite values in `lhs` if they have the same key.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side storage.
    ///   - rhs: The right-hand side storage (can be `nil`).
    /// - Returns: A new storage containing values from both.
    public static func +(lhs: Self, rhs: Self?) -> Self{
        var new = lhs
        new += rhs
        return new
    }
    
    /// Appends values from another storage to this one.
    ///
    /// Values from `rhs` overwrite existing values if they have the same key.
    ///
    /// - Parameters:
    ///   - lhs: The storage to modify.
    ///   - rhs: The storage to append (can be `nil`).
    public static func +=(lhs: inout Self, rhs: Self?){
        rhs?.storage.forEach{ lhs.storage[$0.key] = $0.value }
    }
}

/// A container for a key-value pair in shared storage.
///
/// Used when initializing `EZSharedStorage` from multiple key-value pairs.
///
/// ### Example
/// ```swift
/// extension EZSharedKeyChain<OnboardingViewController> {
///     var onboardingStatus: EZSharedKey<Self, OnboardingStatus> { .init(key: "OnboardingStatus") }
///     var onboardingActions: EZSharedKey<Self, OnboardingActions> { .init(key: "OnboardingActions") }
/// }
///
/// extension EZSharedKey {
///     static var onboardingChain: EZSharedKeyChain<OnboardingViewController> { .init() }
/// }
///
/// let storage = EZSharedStorage([
///     EZSharedContainer(key: .onboardingChain.onboardingStatus, value: currentStatus),
///     EZSharedContainer(key: .onboardingChain.onboardingActions, value: actions)
/// ])
/// ```
public struct EZSharedContainer {
    private(set) var key: any EZSharedKeyProtocol
    private(set) var value: Any
    
    /// Creates a container with a key-value pair.
    ///
    /// - Parameters:
    ///   - key: The key to store.
    ///   - value: The value to store.
    public init<C, T>(key: EZSharedKey<C, T>, value: T){
        self.key = key
        self.value = value
    }
}
