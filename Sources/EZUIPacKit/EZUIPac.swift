//
//  File.swift
//  
//
//  Created by Александр Сенин on 02.06.2023.
//

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(EZSwiftUIBridgeKit)
import EZSwiftUIBridgeKit
#endif

#if canImport(EZObservableKit)
import EZObservableKit
#endif

#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

#if canImport(UIKit) || canImport(Cocoa)
public protocol EZUIPacBaseProtocol: AnyObject{
    associatedtype C: EZUIPacControllerProtocol where C.Router == R
    associatedtype R: EZUIPacRouterProtocol
    associatedtype V: EZUIPacViewProtocol where V.Router == R
    
    var controller: C {get}
    var router: R {get}
    var view: V {get}
}


public protocol EZUIPacProtocol: EZUIPacBaseProtocol{
    var key: UInt { get }
    
    var window: EZUIPacWindow? { get set }
    var rootWindow: EZUIPacWindow? { get }
    var parent: (any EZUIPacProtocol)? { get set }
    var children: [UInt: any EZUIPacProtocol] { get }
    
    var line: EZUIPacLine? { get set }
    var archived: (any EZUIPacProtocol)? { get set }
    var container: EZContainerView { get }
    
    var isTransiting: Bool { get set }
    var isStarted: Bool { get set }
    var supportedOrientations: UIInterfaceOrientationMask { get }
    var currentOrientation: UIInterfaceOrientation? { get set }
    
    var `in`: EZTransitionConfig { get }
    var instead: EZTransitionConfig { get }
    var close: EZTransitionConfig { get }
    var back: EZTransitionConfig { get }
#if targetEnvironment(macCatalyst)
    var openWindow: EZTransitionConfig { get }
#endif
    
    @discardableResult
    func setKey(key: UInt) -> Self
    func addChild(pack: any EZUIPacProtocol)
    func addToParent(pack: any EZUIPacProtocol)
    func remove(pack: any EZUIPacProtocol)
    func removeFromParent()
    
    func forEachAtPacksTree(_ body: (any EZUIPacProtocol) throws -> ()) rethrows
    
    func startAction()
    func openAction()
    func openWithAnimationAction()
    func completedOpenAction()
    func closeAction()
    func closeWithAnimationAction()
    func completedCloseAction()
    func didResizeAction()
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    func didRotateAction(oldOrientation: UIInterfaceOrientation, newOrientation: UIInterfaceOrientation)
#endif
}

open class EZUIPac<
    C: EZUIPacControllerProtocol,
    R: EZUIPacRouterProtocol,
    V: EZUIPacViewProtocol
>: EZUIPacProtocol where C.Router == R, V.Router == R{
    private var keyIncrement: UInt = 1
    
    public private(set) var key: UInt = 0
    public var isTransiting: Bool {
        set(value){ router.stateStorage.isTransiting = value }
        get{ router.stateStorage.isTransiting }
    }
    public var isStarted: Bool {
        set(value){ router.stateStorage.isStarted = value }
        get{ router.stateStorage.isStarted }
    }
    public var supportedOrientations: UIInterfaceOrientationMask { view.supportedOrientations }
    public var currentOrientation: UIInterfaceOrientation? {
        set(value){ router.stateStorage.currentOrientation = value }
        get{ router.stateStorage.currentOrientation }
    }

    public weak var line: EZUIPacLine?
    public var archived: (any EZUIPacProtocol)?
    
    public weak var window: EZUIPacWindow?
    public var rootWindow: EZUIPacWindow?{
        if let window { return window }
        else{ return parent?.rootWindow }
    }
    public weak var parent: (any EZUIPacProtocol)?
    public private(set) var container = EZContainerView()
    
    private(set) var _children: [UInt: any EZUIPacProtocol] = [:]
    public var children: [UInt: any EZUIPacProtocol] { _children }
    

    public private(set) var controller: C
    public private(set) var router: R
    public private(set) var view: V
    
    public convenience init(controller: C.Type = C.self, view: V.Type = V.self){
        self.init(router: .init())
    }
    
    public init(controller: C.Type = C.self, router: R, view: V.Type = V.self){
        self.controller = .init(router: router)
        self.view = .init(router: router)
        self.router = router
        router.stateStorage.setup(self)
        setView()
    }
    
    private func setView(){
        container.addChildView(view.getView(router: router))
        container.ezBounds.add{[weak self] _ in self?.didResizeAction() }
        controller.view = container
    }

    @discardableResult
    public func setKey(key: UInt) -> Self { self.key = key; return self }
    public func addChild(pack: any EZUIPacProtocol) {
        pack.removeFromParent()
        _children[keyIncrement] = pack.setKey(key: keyIncrement)
        pack.parent = self
        keyIncrement += 1
    }
    
    public func addToParent(pack: any EZUIPacProtocol) {
        pack.addChild(pack: self)
    }
        
    public func remove(pack: any EZUIPacProtocol) {
        _children[pack.key] = nil
    }
    
    public func removeFromParent() {
        parent?.remove(pack: self)
    }
    
    public var `in`: EZTransitionConfig { .init(.In, self) }
    public var instead: EZTransitionConfig { .init(.Instead, self) }
    public var close: EZTransitionConfig { .init(.Instead, self) }
    public var back: EZTransitionConfig { .init(.Instead, self).back() }
#if targetEnvironment(macCatalyst)
    public var openWindow: EZTransitionConfig { .init(.Window, nil) }
#endif
    
    public func forEachAtPacksTree(_ body: (any EZUIPacProtocol) throws -> ()) rethrows {
        try body(self)
        try children.forEach{ try $0.value.forEachAtPacksTree(body) }
    }
    
    public func startAction(){
        if router.stateStorage.isStarted == true{ return }
        router.stateStorage.isStarted = true
        controller.initActions()
        view.initActions()
        controller.start()
        view.create()
        controller.didCreate()
    }
    public func openAction(){
        controller.open()
        view.open()
    }
    public func openWithAnimationAction(){
        view.openWithAnimation()
    }
    public func completedOpenAction(){
        controller.completedOpen()
        view.completedOpen()
    }
    public func closeAction(){
        controller.close()
        view.close()
    }
    
    public func closeWithAnimationAction() {
        view.closeWithAnimation()
    }
    public func completedCloseAction(){
        controller.completedClose()
        view.completedClose()
    }
    
    public func didResizeAction(){
        view.didResize()
    }
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    public func didRotateAction(oldOrientation: UIInterfaceOrientation, newOrientation: UIInterfaceOrientation){
        view.didRotate()
    }
#endif
}
#endif
