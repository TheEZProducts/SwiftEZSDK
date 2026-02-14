//
//  EZSUIPackViewProtocol.swift
//  EZSUIPackKit
//
//  Created by Александр Сенин on 07.02.2026.
//

#if canImport(SwiftUI)
import SwiftUI

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@MainActor
public protocol EZSUIPackViewProtocol: View, Equatable {
    associatedtype Mediator: EZSUIPackMediatorProtocol

    var access: Mediator.AccessV { get }

    func makeInput() -> Mediator.InputV
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackViewProtocol {
    nonisolated static public func ==(lhs: Self, rhs: Self) -> Bool { false }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackViewProtocol where Mediator.InputV == Void {
    public func makeInput() -> Mediator.InputV { () }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackViewProtocol where Mediator.InputV == Self {
    public func makeInput() -> Mediator.InputV { self }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZSUIPackViewProtocol {
    public var viewModel: Mediator.ViewModel {
        _read { yield access.viewModel }
    }

    public var inputI: Mediator.InputI {
        _read { yield access.inputI }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZSUIPackV = View & EZSUIPackViewProtocol
#endif
