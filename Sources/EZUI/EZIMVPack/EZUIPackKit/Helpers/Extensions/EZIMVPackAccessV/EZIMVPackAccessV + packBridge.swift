//
//  EZIMVPackAccessV + packBridge.swift
//  EZUIPackKit
//
//  Created by Александр Сенин on 15.02.2026.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation


extension EZIMVPackAccessV where Mediator: EZUIPackMediatorProtocol {
    /// Convenience accessor for the mediator's pack bridge.
    ///
    /// Provides the view with access to the pack bridge for communicating with the
    /// containing `EZUIPack` instance (e.g., accessing the interactor's view controller).
    public var packBridge: EZUIPackBridge {
        get { mediator.packBridge }
    }
}


 
#endif
