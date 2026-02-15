//
//  EZUIPackKit.swift
//  EZUIPackKit
//
//  Created by Александр Сенин on 14.02.2026.
//

#if canImport(UIKit) && !os(watchOS)
@_exported import EZUIPackBaseKit
@_exported import EZTransitionKit

// MARK: - Backward compatibility typealiases
public typealias EZUIMappedAccess = EZPackMappedAccess
public typealias EZUIMediatorAccessI = EZPackMediatorAccessI
public typealias EZUIMediatorAccessV = EZPackMediatorAccessV
#endif
