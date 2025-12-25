//
//  EZUIPackV.swift
//  UIPackkages
//
//  Created by Александр Сенин on 08.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

#if canImport(SwiftUI)
import SwiftUI
#endif

#if canImport(EZSwiftUIBridgeKit)
import EZSwiftUIBridgeKit
#endif

@MainActor
public protocol EZViewProtocol<Mediator> {
    associatedtype Mediator: EZUIPackMediatorProtocol
    var access: Mediator.AccessV! { get set }
    
    init()
    init(mediator: Mediator)
    
    func setupActions() -> Mediator.VActionProvider?
    func create()
}

extension EZViewProtocol where Self: EZViewProtocol {
    public init(mediator: Mediator){
        self.init()
        self.access = mediator.accessV
    }
}

extension EZViewProtocol where Mediator.VActionProvider == Void {
    public func setupActions() -> Mediator.VActionProvider? { () }
}

extension EZViewProtocol {
    public var packBridge: EZUIPackBridge {
        _read { yield access.packBridge }
    }
    
    public var viewModel: Mediator.ViewModel {
        _read { yield access.viewModel }
        nonmutating _modify { yield &access.viewModel }
    }
    
    public var iActions: Mediator.IActionProvider {
        _read { yield access.iActions }
    }
}

extension EZViewProtocol{
    public func create(){}
}

public protocol EZUIPackViewProtocol<Mediator>: EZViewProtocol {
#if !os(tvOS) && !os(watchOS)
    var supportedInterfaceOrientations: UIInterfaceOrientationMask? { get }
    var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation? { get }
    
    
    var preferredStatusBarStyle: UIStatusBarStyle? { get }
    var prefersStatusBarHidden: Bool? { get }
    var preferredStatusBarUpdateAnimation: UIStatusBarAnimation? { get }
#endif
    
#if !os(watchOS)
    func getView() -> EZView
#endif
    
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
    @available(iOS 13.0, tvOS 13.0, *)
    func viewIsAppearing(_ animated: Bool)
    func viewDidAppear(_ animated: Bool)
    func viewWillDisappear(_ animated: Bool)
    func viewDidDisappear(_ animated: Bool)
}

extension EZUIPackViewProtocol {
#if !os(tvOS) && !os(watchOS)
    public var supportedInterfaceOrientations: UIInterfaceOrientationMask? { nil }
    public var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation? { nil }
    
    public var preferredStatusBarStyle: UIStatusBarStyle? { nil }
    public var prefersStatusBarHidden: Bool? { nil }
    public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation? { nil }
#endif
    
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
    @available(iOS 13.0, tvOS 13.0, *)
    public func viewIsAppearing(_ animated: Bool){}
    public func viewDidAppear(_ animated: Bool){}
    public func viewWillDisappear(_ animated: Bool){}
    public func viewDidDisappear(_ animated: Bool){}
}

#if canImport(UIKit) && !os(watchOS)
public typealias EZView = UIView
#elseif canImport(Cocoa)
public typealias EZView = NSView
#endif


#if (canImport(UIKit) || canImport(Cocoa)) && !os(watchOS)
public protocol EZUIPackUIViewProtocol: EZView, EZUIPackViewProtocol {}
extension EZUIPackUIViewProtocol{
    public func getView() -> EZView { self }
}
public typealias EZUIPackV = EZView & EZUIPackUIViewProtocol
#endif

#if os(watchOS)
public protocol EZUIPackUIViewProtocol: EZUIPackViewProtocol {}
public typealias EZUIPackV = EZUIPackUIViewProtocol
#endif


#if canImport(SwiftUI)
@MainActor
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public protocol EZUIPackSViewProtocol: EZUIPackViewProtocol, Equatable{
    associatedtype Body : View
    
    @ViewBuilder @MainActor @preconcurrency var body: Self.Body { get }
    
    var additionalObservableObjects: [any ObservableObject] { get }
    
    init()
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol{
    public var additionalObservableObjects: [any ObservableObject] { [] }
}

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol where Self: View {
    nonisolated
    public static func ==(l: Self, r: Self) -> Bool { false }
    
    public var bMediator: Binding<Mediator.AccessV> { .constant(access) }
    public var binding: Binding<Self> { .constant(self) }
}
 
#if !os(watchOS)
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
#endif

#if !os(watchOS)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
extension EZUIPackSViewProtocol where Self: EZView {
    public var bMediator: Binding<Mediator.AccessV> { .constant(access) }
}
#endif
 
#if !os(watchOS)
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
#endif

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZUIPackSV = View & EZUIPackSViewProtocol

#if !os(watchOS)
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias EZUIPackSUIV = UIView & EZUIPackSViewProtocol
#endif

#endif


open class EZUIPackPlatformsV<M: EZUIPackMediatorProtocol>: EZUIPackViewProtocol {
    public var mediator: M!
    public var access: M.AccessV! {
        set {}
        get { mediator.accessV }
    }
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
#elseif os(visionOS)
        view = visionOS
#endif
        if case .none = self.view {
            view = EZDummyUIPackV(mediator: mediator)
        }
    }
    
#if !os(tvOS) && !os(watchOS)
    open var supportedInterfaceOrientations: UIInterfaceOrientationMask? { view.supportedInterfaceOrientations }
#endif
    open func didInitialize() { view.didInitialize() }
    open func setupActions() -> Mediator.VActionProvider? { view.setupActions() }
    open func create() { view.create() }
    open func willOpen() { view.willOpen() }
    open func animateOpen() { view.animateOpen() }
    open func didOpen() { view.didOpen() }
    open func willClose() { view.willClose() }
    open func animateClose() { view.animateClose() }
    open func didClose() { view.didClose() }
}
#endif
