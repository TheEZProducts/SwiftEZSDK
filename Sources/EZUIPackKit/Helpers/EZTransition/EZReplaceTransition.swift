//
//  EZReplaceTransition.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension EZTransition<UIViewController>{
    public func replace(_ controller: UIViewController) -> any EZReplaceTransitionProtocol<EZChildTransitionContext> {
        if controller.parent is UINavigationController {
            return navigationReplace(controller)
        }else {
            return tabBarReplace(controller)
        }
    }
}

public protocol EZReplaceTransitionProtocol<Context>: EZTransitionProtocol{}
#endif
