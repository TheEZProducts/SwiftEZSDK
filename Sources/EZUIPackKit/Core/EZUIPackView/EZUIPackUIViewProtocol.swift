//
//  EZUIPackUIViewProtocol.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

#if canImport(UIKit) && !os(watchOS)
public typealias EZView = UIView
#elseif canImport(Cocoa)
public typealias EZView = NSView
#endif


#if (canImport(UIKit) || canImport(Cocoa)) && !os(watchOS)
public protocol EZUIPackUIViewProtocol: EZView, EZUIPackViewProtocol {}
extension EZUIPackUIViewProtocol{
    public func getView() -> EZView { self }
}

public typealias EZUIPackV = EZView & EZUIPackUIViewProtocol
#endif


#endif
