//
//  EZUIPackPlatformsAccessV.swift
//  EZUIPackKit
//
//  Created by Александр Сенин on 07.07.2026.
//

#if canImport(UIKit) && !os(watchOS)
import EZIMVPackKit

/// A forwarding access used by `EZUIPackPlatformsV`.
///
/// The platform router does not own an access of its own — it re-exposes the selected
/// platform view's access. Since child views may use different access flavors, the router
/// forwards through the constrained existential, so `setMediator(_:)` lands on the child
/// view's access object.
@MainActor
public struct EZUIPackPlatformsAccessV<M: EZUIPackMediatorProtocol>: EZUIPackViewAccessProtocol {
    public typealias Mediator = M

    let base: any EZUIPackViewAccessProtocol<M>

    /// Read/write access to the shared view model, forwarded to the selected view's access.
    public var viewModel: M.ViewModel {
        get { base.viewModel }
        nonmutating set { base.viewModel = newValue }
    }

    /// Read-only access to the interactor's action interface, forwarded to the selected view's access.
    public var inputI: M.InputI { base.inputI }

    /// Access to the pack bridge, forwarded to the selected view's access.
    public var packBridge: EZUIPackBridge { base.packBridge }

    /// Binds the mediator into the selected view's access.
    public func setMediator(_ mediator: M) { base.setMediator(mediator) }
}
#endif
