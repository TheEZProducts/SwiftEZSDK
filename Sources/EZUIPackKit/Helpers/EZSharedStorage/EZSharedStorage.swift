//
//  EZSharedStorage.swift
//  EZSDK
//
//  Created by Александр Сенин on 23.02.2025.
//

import Foundation

/// Protocol for objects that can provide shared storage to child packs.
///
/// Implement this protocol to allow child packs to access data from their parent.
@MainActor
public protocol EZSharingProtocol {
    /// Shared storage that child packs can access via their mediator's `ezParentShered` property.
    var shared: EZSharedStorage? { get }
}

/// A type-safe storage for sharing data between parent and child packs.
///
/// `EZSharedStorage` provides a dictionary-like interface using `EZSharedKey` for type-safe access.
/// Use this to pass data from a parent pack's interactor to child packs.
///
/// ### Example: Using shared storage
/// ```swift
/// // In parent pack interactor:
/// var shared: EZSharedStorage? {
///     var storage = EZSharedStorage()
///     storage[.userID] = currentUserID
///     storage[.sessionToken] = sessionToken
///     return storage
/// }
///
/// // In child pack mediator:
/// func start() {
///     if let userID = ezParentShered[.userID] {
///         // Use parent's user ID
///     }
/// }
/// ```
public struct EZSharedStorage{
    private var storage = [String: Any]()
    
    /// Accesses a value in the storage using a type-safe key.
    ///
    /// - Parameter key: The key to access.
    /// - Returns: The value associated with the key, or `nil` if not found.
    ///
    /// ### Example
    /// ```swift
    /// storage[.userID] = 123
    /// let id: Int? = storage[.userID]
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
/// let storage = EZSharedStorage([
///     EZSharedContainer(key: .userID, value: 123),
///     EZSharedContainer(key: .sessionToken, value: "abc")
/// ])
/// ```
public struct EZSharedContainer{
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
