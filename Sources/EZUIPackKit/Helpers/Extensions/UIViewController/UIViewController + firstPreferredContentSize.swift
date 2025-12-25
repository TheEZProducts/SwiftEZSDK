//
//  UIViewController + firstPreferredContentSize.swift
//  EZSDK
//
//  Created by Александр Сенин on 25.12.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension UIViewController{
    var firstPreferredContentSize: CGSize? {
        preferredContentSize != .zero ? preferredContentSize : parent?.firstPreferredContentSize
    }
}

#endif
