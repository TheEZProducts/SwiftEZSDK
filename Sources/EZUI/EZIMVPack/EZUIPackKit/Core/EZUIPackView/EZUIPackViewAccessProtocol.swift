//
//  EZUIPackViewAccessProtocol.swift
//  EZUIPackKit
//
//  Created by Александр Сенин on 07.07.2026.
//

#if canImport(UIKit) && !os(watchOS)
import EZIMVPackKit

import EZUIPackHelpersKit

/// The UIKit refinement of the view access abstraction.
///
/// Extends `EZIMVPackViewAccess` with the pack bridge, giving UIKit views access to the
/// containing `EZUIPack` instance (e.g., the interactor's view controller). The view access
/// (`EZIMVPackAccessV`) conforms when its mediator is a UIKit mediator.
@MainActor
public protocol EZUIPackViewAccessProtocol<Mediator>: EZIMVPackViewAccess
    where Mediator: EZUIPackMediatorProtocol
{
    /// Access to the pack bridge for advanced operations.
    var packBridge: EZUIPackBridge { get }
}

extension EZIMVPackAccessV: EZUIPackViewAccessProtocol where Mediator: EZUIPackMediatorProtocol {
    /// Convenience accessor for the mediator's pack bridge.
    ///
    /// Provides the view with access to the pack bridge for communicating with the
    /// containing `EZUIPack` instance (e.g., accessing the interactor's view controller).
    public var packBridge: EZUIPackBridge { mediator.packBridge }
}
#endif
