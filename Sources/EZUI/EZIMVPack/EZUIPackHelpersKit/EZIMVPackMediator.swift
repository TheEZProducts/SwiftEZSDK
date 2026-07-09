//
//  EZIMVPackMediator.swift
//  EZUIPackHelpersKit
//
//  Created by Александр Сенин on 07.02.2026.
//

/// Base class for mediators in the IMV architecture.
///
/// Provides a default `init()`. Platform-specific mediator classes inherit from this:
/// - `EZUIPackMediator` (UIKit — adds `packBridge`)
/// - `EZSUIPackMediator` (SwiftUI)
@MainActor
open class EZIMVPackMediator {
    public init() {}
}
