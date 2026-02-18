//
//  EZSharedKey.swift
//  EZSDK
//
//  Created by Александр Сенин on 23.02.2025.
//

import Foundation

/// Protocol for key chains used to namespace shared storage keys.
///
/// Use key chains to organize keys and prevent naming conflicts.
public protocol EZSharedKeyChainProtocol {}

/// A key chain for organizing shared storage keys.
///
/// Use this to create namespaced keys that are less likely to conflict.
///
/// ### Example
/// ```swift
/// extension EZSharedKeyChain<OnboardingViewController> {
///     var onboardingStatus: EZSharedKey<Self, OnboardingStatus> { .init(key: "OnboardingStatus") }
///     var onboardingActions: EZSharedKey<Self, OnboardingActions> { .init(key: "OnboardingActions") }
/// }
/// ```
public struct EZSharedKeyChain<T>: EZSharedKeyChainProtocol {
    /// Creates a new key chain.
    public init(){}
}

/// Protocol for keys used in shared storage.
///
/// Keys must be hashable and provide a string representation.
public protocol EZSharedKeyProtocol: Hashable{
    /// The string representation of this key.
    var key: String { get }
}

extension EZSharedKeyProtocol{
    /// Equality comparison based on the key string.
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.key == rhs.key }
    
    /// Hash function based on the key string.
    public func hash(into hasher: inout Hasher) { key.hash(into: &hasher) }
}

/// A type-safe key for accessing values in `EZSharedStorage`.
///
/// `EZSharedKey` provides type-safe access to shared storage values. The key includes:
/// - A chain type for namespacing
/// - A value type for type safety
/// - A string identifier for uniqueness
///
/// ### Example: Defining keys
/// ```swift
/// // 1. Define keys for the view controller's shared storage
/// extension EZSharedKeyChain<OnboardingViewController> {
///     var onboardingStatus: EZSharedKey<Self, OnboardingStatus> { .init(key: "OnboardingStatus") }
///     var onboardingActions: EZSharedKey<Self, OnboardingActions> { .init(key: "OnboardingActions") }
/// }
///
/// // 2. Create a static var for easy access to the chain
/// extension EZSharedKey {
///     static var onboardingChain: EZSharedKeyChain<OnboardingViewController> { .init() }
/// }
///
/// // 3. Usage:
/// storage[.onboardingChain.onboardingStatus] = currentStatus
/// let status: OnboardingStatus? = storage[.onboardingChain.onboardingStatus]
/// ezParentShared[.onboardingChain.onboardingActions]?.next()
/// ```
///
/// - Note: The key string is automatically prefixed with the chain and value type names
///   to ensure uniqueness across different key definitions.
public struct EZSharedKey<Chain: EZSharedKeyChainProtocol, Value>: EZSharedKeyProtocol{
    /// The full string key combining chain, identifier, and value type.
    public var key: String { "\(Chain.self)" + keyString + "\(Value.self)" }
    private var keyString: String
    
    /// Creates a shared key.
    ///
    /// - Parameters:
    ///   - chain: The key chain type (defaults to `Chain.self`).
    ///   - type: The value type (defaults to `Value.self`).
    ///   - key: The string identifier for this key.
    public init(chain: Chain.Type = Chain.self, type: Value.Type = Value.self, key: String) {
        self.keyString = key
    }
}
