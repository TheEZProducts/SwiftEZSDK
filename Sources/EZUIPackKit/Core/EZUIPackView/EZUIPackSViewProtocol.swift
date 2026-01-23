//
//  EZUIPackSViewProtocol.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

#if canImport(SwiftUI)
import SwiftUI

import EZSwiftUIBridgeKit

@MainActor
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol EZUIPackSViewProtocol: EZUIPackViewProtocol, Equatable {
    associatedtype Body : View
    
    @ViewBuilder @MainActor @preconcurrency var body: Self.Body { get }
    
    var additionalObservableObjects: [any ObservableObject] { get }
    
    init()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol{
    public var additionalObservableObjects: [any ObservableObject] { [] }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPackSViewProtocol where Self: View {
    public var uiView: EZView? { packBridge.pack?.interactor?.view }
    
    public func getView() -> EZView {
        if let observObj = access.viewModel as? (any ObservableObject) {
            return .ezWrap(
                EZObservableObjectGroup(objects: additionalObservableObjects + [observObj])
            ){ self }
        }else{
            return .ezWrap(
                EZObservableObjectGroup(objects: additionalObservableObjects),
                view: self
            )
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol where Self: View {
    nonisolated
    public static func ==(l: Self, r: Self) -> Bool { false }
    
    public var bAccess: Binding<Mediator.AccessV> { .constant(access) }
    public var bViewModel: Binding<Mediator.ViewModel> { .constant(viewModel) }
    public var binding: Binding<Self> { .constant(self) }
}


@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol where Self: EZView {
    public var bAccess: Binding<Mediator.AccessV> { .constant(access) }
    public var bViewModel: Binding<Mediator.ViewModel> { .constant(viewModel) }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol where Self: EZView {
    public func getView() -> EZView {
        let view = wrappedView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        return self
    }
    
    private func wrappedView() -> EZView {
        if let observObj = access.viewModel as? (any ObservableObject) {
            return .ezWrap(
                EZObservableObjectGroup(objects: additionalObservableObjects + [observObj])
            ) {[weak self] in
                if let self = self { body }
            }
        }else{
            return .ezWrap(
                EZObservableObjectGroup(objects: additionalObservableObjects),
                view: body
            )
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZUIPackSV = View & EZUIPackSViewProtocol

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZUIPackSUIV = UIView & EZUIPackSViewProtocol

#endif
