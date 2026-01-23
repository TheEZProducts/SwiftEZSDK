//
//  EZUIPackPlatformsV.swift
//  EZSDK
//
//  Created by Александр Сенин on 07.01.2026.
//

#if canImport(UIKit) && !os(watchOS)
import Foundation

import UIKit

open class EZUIPackPlatformsV<M: EZUIPackMediatorProtocol>: EZUIPackViewProtocol {
    public var access: M.AccessV { view.access }
    private(set) var view: (any EZUIPackViewProtocol<M>)!
    
    
    open var iOS: (any EZUIPackViewProtocol<M>)? { nil }
    open var iPadOS: (any EZUIPackViewProtocol<M>)? { nil }
    open var macCatalyst: (any EZUIPackViewProtocol<M>)? { nil }
    open var macOS: (any EZUIPackViewProtocol<M>)? { nil }
    open var tvOS: (any EZUIPackViewProtocol<M>)? { nil }
    open var visionOS: (any EZUIPackViewProtocol<M>)? { nil }
    
#if !os(watchOS)
    open func getView() -> EZView {
        view.getView()
    }
#endif
    
    required public init() {
        setView()
    }
    
    open func setView(){
#if targetEnvironment(macCatalyst)
        view = macCatalyst
#elseif os(iOS)
        if UIDevice.current.userInterfaceIdiom == .phone{
            view = iOS
        }else{
            view = iPadOS
        }
#elseif os(macOS)
        view = macOS
#elseif os(tvOS)
        view = tvOS
#elseif os(visionOS)
        view = visionOS
#endif
        if case .none = view {
            fatalError("No view for this platform")
        }
    }
    
#if !os(tvOS) && !os(watchOS)
    open var supportedInterfaceOrientations: UIInterfaceOrientationMask? { view.supportedInterfaceOrientations }
#endif
    open func didInitialize() { view.didInitialize() }
    open func makeContext() -> Mediator.ContextV { view.makeContext() }
    open func create() { view.create() }
    open func willOpen() { view.willOpen() }
    open func animateOpen() { view.animateOpen() }
    open func didOpen() { view.didOpen() }
    open func willClose() { view.willClose() }
    open func animateClose() { view.animateClose() }
    open func didClose() { view.didClose() }
}
#endif
