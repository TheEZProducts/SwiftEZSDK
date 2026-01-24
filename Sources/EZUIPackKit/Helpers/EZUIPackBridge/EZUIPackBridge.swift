//
//  EZUIPackBridge.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

/// A bridge that connects a mediator to its pack.
///
/// The bridge maintains a weak reference to the pack, allowing the mediator to access
/// the pack and its components when needed. This is used internally by the IMV architecture
/// to maintain relationships between components.
///
/// Typically you don't need to interact with this class directly; it's managed automatically
/// by the pack setup process.
@MainActor
open class EZUIPackBridge {
    /// Weak reference to the pack that this bridge connects to.
    ///
    /// Set automatically during pack setup. Use this to access the pack from the mediator.
    public weak var pack: (any EZUIPackProtocol)?
    
    /// Creates a bridge, optionally with an initial pack reference.
    ///
    /// - Parameter pack: The pack to connect to, or `nil` to set later.
    public init(pack: (any EZUIPackProtocol)? = nil) {
        self.pack = pack
    }
}

#endif
