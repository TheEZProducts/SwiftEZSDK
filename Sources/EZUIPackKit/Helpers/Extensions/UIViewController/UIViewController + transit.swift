//
//  UIViewController + transit.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController {
    public var transit: EZTransition<UIViewController> { EZTransition(self) }
}

#endif
