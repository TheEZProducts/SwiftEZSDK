//
//  EZSUIPackInteractorProtocol.swift
//  EZSUIPackKit
//
//  Created by Александр Сенин on 07.02.2026.
//

#if canImport(SwiftUI)
import Foundation

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public protocol EZSUIPackInteractorProtocol: AnyObject {
    associatedtype Mediator: EZSUIPackMediatorProtocol
    associatedtype Context = Void

    var access: Mediator.AccessI { get }

    func makeInput() -> Mediator.InputI
    func makeContext() -> Context

    func didInitialize()
    func start()
    func onAppear()
    func onDisappear()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackInteractorProtocol {
    public var viewModel: Mediator.ViewModel {
        _read { yield access.viewModel }
        _modify { yield &access.viewModel }
    }

    public var inputV: Mediator.InputV {
        _read { yield access.inputV }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackInteractorProtocol where Context == Void {
    public func makeContext() -> Context { () }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackInteractorProtocol where Mediator.InputI == Void {
    public func makeInput() -> Mediator.InputI { () }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackInteractorProtocol where Mediator.InputI == Self {
    public func makeInput() -> Mediator.InputI { self }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackInteractorProtocol {
    public func didInitialize() {}
    public func start() {}
    public func onAppear() {}
    public func onDisappear() {}
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZSUIPackI = EZSUIPackInteractorProtocol
#endif
