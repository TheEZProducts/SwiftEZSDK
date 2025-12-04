//
//  EZDeinitAnchor.swift
//  EZSDK
//
//  Created by Александр Сенин on 03.12.2025.
//

import Foundation

#if canImport(EZAssociatedKit)
import EZAssociatedKit
#endif

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class EZDeinitAnchor: Sendable {
    private let deinitAction: EZSendableWrapper<@Sendable () -> ()>
    
    public init(deinitAction: @Sendable @escaping () -> ()) {
        self.deinitAction = .init(wrappedValue: deinitAction)
    }
    
    public func performAction() {
        deinitAction.update {
            $0()
            $0 = {}
        }
    }
    
    deinit { performAction() }
}

#if canImport(EZAssociatedKit) && canImport(ObjectiveC)
extension EZDeinitAnchor {
    @discardableResult
    public func ezSnapToObject(_ object: AnyObject) -> Self {
        EZAssociated(object).set(self, .random, .OBJC_ASSOCIATION_RETAIN)
        return self
    }
}
#endif
