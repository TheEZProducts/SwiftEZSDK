//
//  File.swift
//  
//
//  Created by Александр Сенин on 29.05.2023.
//

import Foundation

/// Lifetime anchor that automatically removes an observer on deinitialization.
///
/// `EZObserveAnchorObject` holds a removal handle and calls `remove()` in `deinit`.
/// This is useful when you want the observer to stay subscribed only while some object
/// is alive (e.g. a view model, controller, or a scoped owner).
///
/// ### Example
/// ```swift
/// final class Owner {
///     private var anchor: EZObserveAnchorObject?
///
///     func start() {
///         let token = $value.add { _ in /* ... */ }
///         anchor = token.anchorObject // auto-unsubscribe when `Owner` is deallocated
///     }
/// }
/// ```
final public class EZObserveAnchorObject: Sendable {
    private let result: EZObserverTokenRemoveProtocol?
    deinit { result?.remove() }
    init(_ result: EZObserverTokenRemoveProtocol) { self.result = result }
}

/// Minimal interface for a removable observation token.
///
/// Conformers can unsubscribe by calling `remove()`.
public protocol EZObserverTokenRemoveProtocol: Sendable {
    func remove()
}

/// Public interface for observation tokens returned by subscription APIs.
///
/// In addition to `remove()`, a token can:
/// - provide an `anchorObject` to tie the subscription lifetime to an object,
/// - trigger the observer action immediately via `use(_:)`.
public protocol EZObserverTokenProtocol: EZObserverTokenRemoveProtocol {
    /// Returns an anchor object that removes this observer in `deinit`.
    var anchorObject: EZObserveAnchorObject { get }
    
    /// Invokes the observer action immediately using the current stored value.
    ///
    /// The token reads the current value from its storage and re-emits it as a change event.
    ///
    /// - Parameter type: Controls how the event is delivered (e.g. wrapper changes).
    /// - Returns: `self` for fluent chaining.
    @discardableResult
    func use(_ type: EZSetType) -> Self
}

/// Concrete observation token returned by subscription APIs.
///
/// An `EZObserverToken` keeps the observer registered until it is removed. You can:
/// - unsubscribe manually by calling `remove()`,
/// - attach the token to an `anchorObject` so it auto-unsubscribes on deinit,
/// - call `use(_:)` to trigger the observer immediately with the current value.
///
/// ### Example: keep token alive
/// ```swift
/// final class Owner {
///     private var token: EZObserverToken<Int>?
///
///     func start() {
///         token = $count.add { change in
///             print(change.new)
///         }
///     }
/// }
/// ```
///
/// ### Example: immediate first delivery
/// ```swift
/// let token = $count.add { change in
///     print("initial/new:", change.new)
/// }
/// token.use() // emits current value immediately
/// ```
///
/// ### Example: anchor-based lifetime
/// ```swift
/// let token = $count.add { _ in }
/// let anchor = token.anchorObject
/// _ = anchor
/// // When `anchor` is released/deallocated, the observer is removed.
/// ```
public struct EZObserverToken<Value>: EZObserverTokenProtocol, Sendable {
    let id: UInt
    private(set) weak var storage: (any EZObserversStorageProtocol<Value>)?
    let action: EZObserverAction<Value>
    let removeAction: EZObserverAction<Value>?
    let wrapper: EZObserverWrapperProtocol?
    /// Anchor object that removes this observer when the anchor is deallocated.
    public var anchorObject: EZObserveAnchorObject { EZObserveAnchorObject(self) }
    
    /// Gets or sets the underlying observable value.
    ///
    /// - Reading returns the current value from the underlying storage.
    /// - Setting assigns a new value using the default `.common` set type.
    ///
    /// Note: assigning `nil` does nothing.
    public var value: Value? {
        nonmutating set(value) { if let value { storage?.set(value: value, .common) } }
        get { storage?.get() }
    }
    
    /// Invokes the observer action immediately using the current stored value.
    ///
    /// This re-emits the current value as an event (`old == new == current`) and returns `self`.
    /// If the underlying storage no longer exists, this is a no-op.
    @discardableResult
    public func use(_ type: EZSetType = .common) -> Self {
        guard let value else {return self}
        use(old: value, new: value, type)
        return self
    }
    
    func use(old: Value, new: Value, _ type: EZSetType) {
        var wrapper = self.wrapper
        if case .changeWrapper(let newWrapper) = type { wrapper = newWrapper }
        action.use(value: EZObserverValue(
            old: old,
            new: new,
            wrapper: wrapper,
            removeObserverAction: remove
        ))
    }
    
    /// Unsubscribes this observer from its storage.
    public func remove() { storage?.remove(id: id) }
}
