//
//  File.swift
//  
//
//  Created by Александр Сенин on 02.06.2023.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

#if canImport(SwiftUI)
import SwiftUI
import EZSwiftUIBridgeKit
#endif

public protocol EZViewProtocol<Router>: EZUIPacWithRouterProtocol{
    func initActions()
    func create()
}

extension EZViewProtocol{
    public func initActions(){}
    public func create(){}
}

public protocol EZUIPacViewProtocol<Router>: EZViewProtocol, EZUIPacWithRouterProtocol, EZUIPacWithStateStorage{
    func getView(router: Router) -> EZView
    
    func open()
    func openWithAnimation()
    func completedOpen()
    func close()
    func closeWithAnimation()
    func completedClose()
    func didResize()
    
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    var supportedOrientations: UIInterfaceOrientationMask { get }
    func didRotate(oldOrientation: UIInterfaceOrientation, newOrientation: UIInterfaceOrientation)
#endif
}

extension EZUIPacViewProtocol{
    public func open(){}
    public func openWithAnimation(){}
    public func completedOpen(){}
    public func close(){}
    public func closeWithAnimation(){}
    public func completedClose(){}
    public func didResize(){}
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    public func didRotate(oldOrientation: UIInterfaceOrientation, newOrientation: UIInterfaceOrientation){}
#endif
}

#if canImport(UIKit)
public typealias EZView = UIView
#elseif canImport(Cocoa)
public typealias EZView = NSView
#endif

#if canImport(UIKit) || canImport(Cocoa)
extension EZUIPacWithRouterProtocol where Self: EZView{
    public init(router: Router){
        self.init(frame: .zero)
        self.router = router
    }
}
#endif

#if canImport(UIKit) || canImport(Cocoa)
public protocol EZUIPacUIViewProtocol: EZView, EZUIPacViewProtocol, EZUIPacWithRouterProtocol{}
extension EZUIPacUIViewProtocol{
    public func getView(router: Router) -> EZView { self }
}
public typealias EZUIPacV = EZView & EZUIPacUIViewProtocol
#endif

#if canImport(SwiftUI)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
public protocol EZUIPacSViewProtocol: View, EZUIPacViewProtocol, EZUIPacWithRouterProtocol, Equatable{
    associatedtype ViewStorage: ObservableObject
    var viewStorage: ViewStorage { get set }
    init()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPacSViewProtocol{
    public var viewStorage: EZObservableObjectGroup {
        get{EZObservableObjectGroup(objects: [])}
        set{}
    }
    
    public static func ==(l: Self, r: Self) -> Bool{ false }
    
    public init(router: Router) {
        self.init()
        self.router = router
    }
    
    public var binding: Binding<Self> { .constant(self) }
    public var bViewStorage: Binding<ViewStorage> { .constant(viewStorage) }
    public var bRouter: Binding<Router> { .constant(router) }
}
 
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPacSViewProtocol {
    public func getView(router: Router) -> EZView {
        if let observObj = router as? (any ObservableObject){
            return .ezWrap(EZObservableObjectGroup(observObj, viewStorage)){ self }
        }else{
            return .ezWrap(view: self)
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
public typealias EZUIPacSV = EZUIPacSViewProtocol
#endif
