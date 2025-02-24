//
//  EZUIPackV.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
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

extension EZUIPackWithMediatorProtocol where Self: EZViewProtocol{
    public init(mediator: Mediator){
        self.init()
        self.mediator = mediator
    }
}

@MainActor
public protocol EZViewProtocol<Mediator>: EZUIPackWithMediatorProtocol{
    init()
    
    func setupActions()
    func create()
}

extension EZViewProtocol where Mediator: EZUIPackMediatorWithActionProviders{
    public var iActions: Mediator.InteractorActionProvider.Provider {
        _read{ yield mediator.iActions.provider }
    }
    public var vActions: Mediator.ViewActionProvider.Provider  {
        _read{ yield mediator.vActions.provider }
        nonmutating _modify{ yield &mediator.vActions.provider }
    }
}

extension EZViewProtocol{
    public func setupActions(){}
    public func create(){}
}

public protocol EZUIPackViewProtocol<Mediator>: EZViewProtocol{
    var supportedInterfaceOrientations: UIInterfaceOrientationMask? { get }
    var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation? { get }
    
    
    var preferredStatusBarStyle: UIStatusBarStyle? { get }
    var prefersStatusBarHidden: Bool? { get }
    var preferredStatusBarUpdateAnimation: UIStatusBarAnimation? { get }
    
    func getView() -> EZView
    
    func didInitialize()
    func willOpen()
    func animateOpen()
    func didOpen()
    func didInstall()
    func willClose()
    func animateClose()
    func didClose()
    
    
    func viewDidLoad()
    func viewWillAppear(_ animated: Bool)
    @available(iOS 13.0, *)
    func viewIsAppearing(_ animated: Bool)
    func viewDidAppear(_ animated: Bool)
    func viewWillDisappear(_ animated: Bool)
    func viewDidDisappear(_ animated: Bool)
}

extension EZUIPackViewProtocol{
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask? { nil }
    public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation? { nil }
    
    public var preferredStatusBarStyle: UIStatusBarStyle? { nil }
    public var prefersStatusBarHidden: Bool? { nil }
    public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation? { nil }
    
    public func didInitialize(){}
    public func willOpen(){}
    public func animateOpen(){}
    public func didOpen(){}
    public func didInstall(){}
    public func willClose(){}
    public func animateClose(){}
    public func didClose(){}
    
    
    public func viewDidLoad(){}
    public func viewWillAppear(_ animated: Bool){}
    @available(iOS 13.0, *)
    public func viewIsAppearing(_ animated: Bool){}
    public func viewDidAppear(_ animated: Bool){}
    public func viewWillDisappear(_ animated: Bool){}
    public func viewDidDisappear(_ animated: Bool){}
}

#if canImport(UIKit)
public typealias EZView = UIView
#elseif canImport(Cocoa)
public typealias EZView = NSView
#endif


#if canImport(UIKit) || canImport(Cocoa)
public protocol EZUIPackUIViewProtocol: EZView, EZUIPackViewProtocol{}
extension EZUIPackUIViewProtocol{
    public func getView() -> EZView { self }
}
public typealias EZUIPackV = EZView & EZUIPackUIViewProtocol
#endif


#if canImport(SwiftUI)
@MainActor
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
public protocol EZUIPackSViewProtocol: EZUIPackViewProtocol, Equatable{
    associatedtype Body : View
    
    @ViewBuilder @MainActor @preconcurrency var body: Self.Body { get }
    
    var additionalObservableObjects: [any ObservableObject] { get }
    
    init()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPackSViewProtocol{
    public var additionalObservableObjects: [any ObservableObject] { [] }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPackSViewProtocol where Self: View {
    nonisolated
    public static func ==(l: Self, r: Self) -> Bool{ false }
    
    public var bMediator: Binding<Mediator> { .constant(mediator) }
    public var binding: Binding<Self> { .constant(self) }
}
 
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPackSViewProtocol where Self: View {
    public var uiView: EZView? { packBridge.pack?.view }
    
    public func getView() -> EZView {
        if let observObj = mediator as? (any ObservableObject){
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

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPackSViewProtocol where Self: EZView {
    public var bMediator: Binding<Mediator> { .constant(mediator) }
}
 
@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
extension EZUIPackSViewProtocol where Self: EZView {
    public func getView() -> EZView {
        let view = wrappedView()
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(view)
        return self
    }
    
    private func wrappedView() -> EZView{
        if let observObj = mediator as? (any ObservableObject){
            return .ezWrap(
                EZObservableObjectGroup(objects: additionalObservableObjects + [observObj])
            ){[weak self] in
                if let self = self {
                    body
                }
            }
        }else{
            return .ezWrap(
                EZObservableObjectGroup(objects: additionalObservableObjects),
                view: body
            )
        }
    }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
public typealias EZUIPackSV = View & EZUIPackSViewProtocol

@available(macOS 10.15, iOS 13.0, tvOS 13.0, *)
public typealias EZUIPackSUIV = UIView & EZUIPackSViewProtocol
#endif


open class EZUIPackPlatformsV<M: EZUIPackMediatorProtocol>: EZUIPackViewProtocol{
    public var mediator: M!
    private(set) var view: (any EZUIPackViewProtocol<M>)?
    
    
    open var iOS: (any EZUIPackViewProtocol<M>)? { nil }
    open var iPadOS: (any EZUIPackViewProtocol<M>)? { nil }
    open var macCatalyst: (any EZUIPackViewProtocol<M>)? { nil }
    open var macOS: (any EZUIPackViewProtocol<M>)? { nil }
    open var tvOS: (any EZUIPackViewProtocol<M>)? { nil }
    
    
    open func getView() -> EZView {
        view?.getView() ?? EZView()
    }
    
    required public init(){}
    required public init(mediator: M) {
        self.mediator = mediator
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
#endif
    }
    
    open var supportedInterfaceOrientations: UIInterfaceOrientationMask? { view?.supportedInterfaceOrientations }
    open func didInitialize(){ view?.didInitialize() }
    open func setupActions(){ view?.setupActions() }
    open func create(){ view?.create() }
    open func willOpen(){ view?.willOpen() }
    open func animateOpen(){ view?.animateOpen() }
    open func didOpen(){ view?.didOpen() }
    open func willClose(){ view?.willClose() }
    open func animateClose(){ view?.animateClose() }
    open func didClose(){ view?.didClose() }
}

