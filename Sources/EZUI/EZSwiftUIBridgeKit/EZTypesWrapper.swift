//
//  EZTypesWrapper.swift
//
//
//  Created by Александр Сенин on 04.06.2023.
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Platform typealiases used by EZSDK to write cross-platform UI helpers.
///
/// This file defines common names for UIKit/AppKit types:
/// - `EZView` maps to `UIView` on UIKit and `NSView` on AppKit.
/// - When SwiftUI is available, helper typealiases map to the appropriate
///   `*ViewRepresentable` and `*HostingController` types.

#if canImport(UIKit) && !os(watchOS)
/// SwiftUI representable typealias for UIKit.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
typealias EZViewRepresentable = UIViewRepresentable

/// SwiftUI hosting controller typealias for UIKit.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
typealias EZHostingController = UIHostingController

/// Cross-platform view type.
///
/// - UIKit: `UIView`
/// - AppKit: `NSView`
public typealias EZView = UIView
#elseif canImport(Cocoa)
/// SwiftUI representable typealias for AppKit.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
typealias EZViewRepresentable = NSViewRepresentable

/// SwiftUI hosting controller typealias for AppKit.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
typealias EZHostingController = NSHostingController

/// Cross-platform view type.
///
/// - UIKit: `UIView`
/// - AppKit: `NSView`
public typealias EZView = NSView
#endif
