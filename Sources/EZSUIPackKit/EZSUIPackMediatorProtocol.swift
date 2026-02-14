//
//  EZSUIPackMediatorProtocol.swift
//  EZSUIPackKit
//
//  Created by Александр Сенин on 07.02.2026.
//

#if canImport(SwiftUI)
import SwiftUI
import Combine

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public protocol EZSUIPackMediatorProtocol: EZPackMediatorBaseProtocol where ViewModel: ObservableObject {}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackMediatorProtocol where ViewModel == EZSUIPackVoidViewModel {
    public var viewModel: ViewModel {
        get { .shared }
        set {}
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public final class EZSUIPackVoidViewModel: ObservableObject {
    public static let shared = EZSUIPackVoidViewModel()
    private init() {}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
open class EZSUIPackMediator {
    public init() {}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZSUIPackM = EZSUIPackMediatorProtocol & EZSUIPackMediator
#endif
