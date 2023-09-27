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
public protocol EZUIPacBaseProtocol<PackProtocol>: AnyObject{
    associatedtype C: EZUIPacControllerProtocol where C.Router == R
    associatedtype R: EZUIPacRouterProtocol
    associatedtype V: EZUIPacViewProtocol where V.Router == R
    associatedtype PackProtocol
    
    var controller: C {get}
    var router: R {get}
    var view: V {get}
}

public protocol EZUIPacBaseWithActionsProtocol<PackProtocol>: EZUIPacBaseProtocol{
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

public protocol EZUIPacBaseWithTreeProtocol<PackProtocol>: EZUIPacBaseProtocol{
    var key: UInt { get }
    var window: EZUIPacWindow? { get set }
    var rootWindow: EZUIPacWindow? { get }
    
    var parent: (PackProtocol)? { get set }
    var children: [UInt: PackProtocol] { get }
    
    @discardableResult
    func setKey(key: UInt) -> Self
    func addChild(pack: PackProtocol)
    func addToParent(pack: PackProtocol)
    func remove(pack: PackProtocol)
    func removeFromParent()
    
    func forEachAtPacksTree(_ body: (PackProtocol) throws -> ()) rethrows
}

public protocol EZUIPacBaseWithContainerProtocol<PackProtocol>: EZUIPacBaseProtocol{
    var container: EZContainerView { get }
}

public protocol EZUIPacBaseSupportRotationProtocol<PackProtocol>: EZUIPacBaseProtocol{
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    var supportedOrientations: UIInterfaceOrientationMask { get }
    var currentOrientation: UIInterfaceOrientation? { get set }
#endif
}

public protocol EZUIPacBaseSupportTransitionProtocol<PackProtocol>:
    EZUIPacBaseWithActionsProtocol,
    EZUIPacBaseWithTreeProtocol,
    EZUIPacBaseWithContainerProtocol,
    EZUIPacBaseSupportRotationProtocol
{
    var line: EZUIPacLine? { get set }
    var archived: (PackProtocol)? { get set }
    
    var isTransiting: Bool { get set }
    var isStarted: Bool { get set }
    
    var `in`: EZTransitionConfig { get }
    var instead: EZTransitionConfig { get }
    var close: EZTransitionConfig { get }
    var back: EZTransitionConfig { get }
#if targetEnvironment(macCatalyst)
    var openWindow: EZTransitionConfig { get }
#endif
}

public protocol EZUIPacProtocol: EZUIPacBaseSupportTransitionProtocol<(any EZUIPacProtocol)>{}

open class EZUIPac<
    C: EZUIPacControllerProtocol,
    R: EZUIPacRouterProtocol,
    V: EZUIPacViewProtocol
>: EZUIPacProtocol where C.Router == R, V.Router == R{
    //MARK: - Property
    //MARK: - Base
    open private(set) var controller: C
    open private(set) var router: R
    open private(set) var view: V
    
    //MARK: - WithTree
    private var keyIncrement: UInt = 1
    open private(set) var key: UInt = 0
    
    open weak var window: EZUIPacWindow?
    open var rootWindow: EZUIPacWindow?{
        if let window { return window }
        else{ return parent?.rootWindow }
    }
    open weak var parent: (any EZUIPacProtocol)?
    open var children: [UInt: any EZUIPacProtocol] = [:]
    
    //MARK: - WithContainer
    open private(set) var container = EZContainerView()
    
    //MARK: - SupportRotation
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    open var supportedOrientations: UIInterfaceOrientationMask { view.supportedOrientations }
    open var currentOrientation: UIInterfaceOrientation? {
        set(value){ router.stateStorage.currentOrientation = value }
        get{ router.stateStorage.currentOrientation }
    }
#endif
    
    //MARK: - SupportTransition
    open weak var line: EZUIPacLine?
    open var archived: (any EZUIPacProtocol)?
    
    open var isTransiting: Bool {
        set(value){ router.stateStorage.isTransiting = value }
        get{ router.stateStorage.isTransiting }
    }
    open var isStarted: Bool {
        set(value){ router.stateStorage.isStarted = value }
        get{ router.stateStorage.isStarted }
    }
    
    
    //MARK: - Metods
    //MARK: - EZUIPac
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
    
    open func setView(){
        container.addChildView(view.getView(router: router))
        container.ezBounds.add{[weak self] _ in self?.didResizeAction() }
        controller.view = container
    }

    //MARK: - WithTree
    open func createKey() -> UInt {
        let key = keyIncrement
        keyIncrement += 1
        return key
    }
    
    @discardableResult
    open func setKey(key: UInt) -> Self { self.key = key; return self }
    open func addChild(pack: any EZUIPacProtocol) {
        let key = createKey()
        pack.removeFromParent()
        children[key] = pack.setKey(key: key)
        pack.parent = self
    }
    
    open func addToParent(pack: any EZUIPacProtocol) {
        pack.addChild(pack: self)
    }
        
    open func remove(pack: any EZUIPacProtocol) {
        children[pack.key] = nil
    }
    
    open func removeFromParent() {
        parent?.remove(pack: self)
    }
    
    open func forEachAtPacksTree(_ body: (any EZUIPacProtocol) throws -> ()) rethrows {
        try body(self)
        try children.forEach{ try $0.value.forEachAtPacksTree(body) }
    }
    
    
    //MARK: - SupportTransition
    open var `in`: EZTransitionConfig { .init(.In, self) }
    open var instead: EZTransitionConfig { .init(.Instead, self) }
    open var close: EZTransitionConfig { .init(.Instead, self) }
    open var back: EZTransitionConfig { .init(.Instead, self).back() }
#if targetEnvironment(macCatalyst)
    open var openWindow: EZTransitionConfig { .init(.Window, nil) }
#endif
    
    //MARK: - WithActions
    open func startAction(){
        if router.stateStorage.isStarted == true{ return }
        router.stateStorage.isStarted = true
        controller.initActions()
        view.initActions()
        controller.start()
        view.create()
        controller.didCreate()
    }
    open func openAction(){
        controller.open()
        view.open()
    }
    open func openWithAnimationAction(){
        view.openWithAnimation()
    }
    open func completedOpenAction(){
        controller.completedOpen()
        view.completedOpen()
    }
    open func closeAction(){
        controller.close()
        view.close()
    }
    
    open func closeWithAnimationAction() {
        view.closeWithAnimation()
    }
    open func completedCloseAction(){
        controller.completedClose()
        view.completedClose()
    }
    
    open func didResizeAction(){
        view.didResize()
    }
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    open func didRotateAction(oldOrientation: UIInterfaceOrientation, newOrientation: UIInterfaceOrientation){
        view.didRotate(oldOrientation: oldOrientation, newOrientation: newOrientation)
    }
#endif
}
#endif
