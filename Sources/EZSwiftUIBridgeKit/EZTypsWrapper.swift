//
//  File.swift
//  
//
//  Created by Александр Сенин on 04.06.2023.
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(UIKit)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
typealias EZViewRepresentable = UIViewRepresentable

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
typealias EZHostingController = UIHostingController

public typealias EZView = UIView
#elseif canImport(Cocoa)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
typealias EZViewRepresentable = NSViewRepresentable

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
typealias EZHostingController = NSHostingController

public typealias EZView = NSView
#endif
