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

#if canImport(UIKit)
public typealias EZViewController = UIViewController
#elseif canImport(Cocoa)
public typealias EZViewController = NSViewController
#endif


#if canImport(UIKit) || canImport(Cocoa)
public protocol EZUIPacBaseProtocol: EZViewController, AnyObject{
    associatedtype C: EZUIPacControllerProtocol where C.Router == R
    associatedtype R: EZUIPacRouterProtocol
    associatedtype V: EZUIPacViewProtocol where V.Router == R
    
    var ezController: C {get}
    var ezRouter: R {get}
    var ezView: V {get}
}

public protocol EZUIPacBaseWithActionsProtocol: EZUIPacBaseProtocol{
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

public protocol EZUIPacBaseWithContainerProtocol: EZUIPacBaseProtocol{
    var container: EZContainerView { get }
}

public protocol EZUIPacBaseSupportRotationProtocol: EZUIPacBaseProtocol{
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    var supportedOrientations: UIInterfaceOrientationMask { get }
    var currentOrientation: UIInterfaceOrientation? { get set }
#endif
}

public protocol EZUIPacBaseSupportTransitionProtocol:
    EZUIPacBaseWithActionsProtocol,
    EZUIPacBaseWithContainerProtocol,
    EZUIPacBaseSupportRotationProtocol
{
    var line: EZUIPacLine? { get set }
    var archived: (any EZUIPacProtocol)? { get set }
    
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

public protocol EZUIPacProtocol: EZUIPacBaseSupportTransitionProtocol{}

open class EZUIPac<
    C: EZUIPacControllerProtocol,
    R: EZUIPacRouterProtocol,
    V: EZUIPacViewProtocol
>: UIViewController, EZUIPacProtocol where C.Router == R, V.Router == R{
    //MARK: - Property
    //MARK: - Base
    open private(set) var ezController: C
    open private(set) var ezRouter: R
    open private(set) var ezView: V
    
    //MARK: - WithContainer
    open private(set) var container = EZContainerView()
    
    //MARK: - SupportRotation
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    open var supportedOrientations: UIInterfaceOrientationMask { ezView.supportedOrientations }
    open var currentOrientation: UIInterfaceOrientation? {
        set(value){ ezRouter.stateStorage.currentOrientation = value }
        get{ ezRouter.stateStorage.currentOrientation }
    }
#endif
    
    //MARK: - SupportTransition
    open weak var line: EZUIPacLine?
    open var archived: (any EZUIPacProtocol)?
    
    open var isTransiting: Bool {
        set(value){ ezRouter.stateStorage.isTransiting = value }
        get{ ezRouter.stateStorage.isTransiting }
    }
    open var isStarted: Bool {
        set(value){ ezRouter.stateStorage.isStarted = value }
        get{ ezRouter.stateStorage.isStarted }
    }
    
    
    //MARK: - Metods
    //MARK: - EZUIPac
    public convenience init(ezController: C.Type = C.self, view: V.Type = V.self){
        self.init(router: .init())
    }
    
    public init(ezController: C.Type = C.self, router: R, view: V.Type = V.self){
        self.ezController = .init(router: router)
        self.ezView = .init(router: router)
        self.ezRouter = router
        
        super.init(nibName: nil, bundle: nil)
        
        router.stateStorage.setup(self)
        setView()
    }

    open func setView(){
        container.addChildView(ezView.getView(router: ezRouter))
        container.ezBounds.add{[weak self] _ in self?.didResizeAction() }
        ezController.view = container
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
        if ezRouter.stateStorage.isStarted == true{ return }
        ezRouter.stateStorage.isStarted = true
        ezController.initActions()
        ezView.initActions()
        ezController.start()
        ezView.create()
        ezController.didCreate()
    }
    open func openAction(){
        ezController.open()
        ezView.open()
    }
    open func openWithAnimationAction(){
        ezView.openWithAnimation()
    }
    open func completedOpenAction(){
        ezController.completedOpen()
        ezView.completedOpen()
    }
    open func closeAction(){
        ezController.close()
        ezView.close()
    }
    
    open func closeWithAnimationAction() {
        ezView.closeWithAnimation()
    }
    open func completedCloseAction(){
        ezController.completedClose()
        ezView.completedClose()
    }
    
    open func didResizeAction(){
        ezView.didResize()
    }
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    open func didRotateAction(oldOrientation: UIInterfaceOrientation, newOrientation: UIInterfaceOrientation){
        ezView.didRotate(oldOrientation: oldOrientation, newOrientation: newOrientation)
    }
#endif
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
#endif
