//
//  File.swift
//  
//
//  Created by Александр Сенин on 02.06.2023.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif
import EZBuilderKit

extension EZTransitionConfig{
    public enum TransitionType{
        case In
        case Instead
#if targetEnvironment(macCatalyst)
        case Window
#endif
    }
}

public struct EZTransitionConfig{
    private(set) var _type: TransitionType
    private(set) var _safe: Bool = true
    
    public func safe(_ value: Bool) -> Self{
        var new = self
        new._safe = value
        return new
    }
    
#if canImport(UIKit) ||  canImport(Cocoa)
    private(set) var _fromPack: (any EZUIPacProtocol)?
    private(set) var _toPack: (any EZUIPacProtocol)?
    private(set) var _toLine: EZUIPacLine?
    private(set) var _archivedPack: (any EZUIPacProtocol)?
    
    private(set) var _container: EZView?
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    private(set) var _autoResizeContainerOnRotation: Bool = false
#endif
    
    private(set) var _animation: EZTransitionAnimation = .init()
    
    public init(_ type: TransitionType, _ line: EZUIPacLine){
        self.init(type, line.currentPack)
    }
    
    public init(_ type: TransitionType, _ pack: (any EZUIPacProtocol)? = nil){
        _type = type
        _fromPack = pack
    }
    
    public func line(_ line: EZUIPacLine) -> Self{
        var new = self
        new._toLine = line
        return new
    }
    
    public func pack<C, R, V, Pack: EZUIPac<C, R, V>>(_ pack: Pack) -> Self{
        var new = self
        new._toPack = pack
        return new
    }
    
    public func pack(_ pack: (any EZUIPacProtocol)? = nil) -> Self{
        var new = self
        new._toPack = pack
        return new
    }
    
    public func back() -> Self{
        var new = self
        new._toPack = _fromPack?.archived
        return new
    }
    
    public func close() -> Self{ self }
    
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    public func container(_ view: EZView, autoResizeOnRotation: Bool = true) -> Self{
        var new = self
        new._container = view
        new._autoResizeContainerOnRotation = autoResizeOnRotation
        return new
    }
#else
    public func container(_ view: EZView) -> Self{
        var new = self
        new._container = view
        return new
    }
#endif
    
    public func archive<C, R, V, Pack: EZUIPac<C, R, V>>(_ pack: Pack) -> Self{
        var new = self
        new._archivedPack = pack
        return new
    }
    
    public func archive(_ pack: (any EZUIPacProtocol)? = nil) -> Self{
        var new = self
        new._archivedPack = pack ?? _fromPack
        return new
    }
    
    public func animation(_ animation: EZTransitionAnimation) -> Self{
        var new = self
        new._animation = animation
        return new
    }

    @MainActor
    @discardableResult
    public func transit() -> (any EZUIPacProtocol)?{
        EZTransition.transit(self)
    }
#endif
}

public struct EZTransition{
#if canImport(UIKit) || canImport(Cocoa)
    @MainActor
    public static func `in`(_ pack: (any EZUIPacProtocol)?) -> EZTransitionConfig{ .init(.In, pack) }

    @MainActor
    public static func instead(_ pack: (any EZUIPacProtocol)?) -> EZTransitionConfig{ .init(.Instead, pack) }
    
    @MainActor
    public static func close(_ pack: (any EZUIPacProtocol)?) -> EZTransitionConfig{ .init(.Instead, pack) }
    
    @MainActor
    public static func back(_ pack: (any EZUIPacProtocol)?) -> EZTransitionConfig{ .init(.Instead, pack).back() }
    
#if targetEnvironment(macCatalyst)
    @MainActor
    public static var window: EZTransitionConfig { .init(.Window, nil) }
#endif
    
    @MainActor
    static func transit(_ config: EZTransitionConfig) -> (any EZUIPacProtocol)?{
        let config = setLinePack(config)
        config._toPack?.ezController.beginAppearanceTransition(true, animated: false)
        switch config._type{
            case .In: return transitIn(config)
            case .Instead: return transitInstead(config)
#if targetEnvironment(macCatalyst)
            case .Window: return transitWindow(config)
#endif
        }
    }
    
    static private func setLinePack(_ config: EZTransitionConfig) -> EZTransitionConfig{
        if config._toPack == nil { return config.pack(config._toLine?.currentPack) }
        else{ return config }
    }
    
    //MARK: - In
    @MainActor
    static private func transitIn(_ config: EZTransitionConfig) -> (any EZUIPacProtocol)?{
        if !checkValid(config) { return nil }
        
        config._animation.build{$0
            .setPacks{$0
                .toPack(config._toPack)
            }
            .setActions{ $0
                .prepareAction { prepareIn(config) }
                .animationAction { animationIn(config) }
                .completionAction { completionIn(config) }
            }
        }.animate()

        return config._toPack
    }
    
    @MainActor
    static private func prepareIn(_ config: EZTransitionConfig){
        config._toPack?.isTransiting = true
        if let pack = config._toPack{
            config._toLine?.setPack(pack)
        }
        setChildIn(config)
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
        rotateIn(config)
#endif
        useStartActions(config)
    }
    
    @MainActor
    static private func animationIn(_ config: EZTransitionConfig){
        config._toPack?.openWithAnimationAction()
    }
    
    @MainActor
    static private func completionIn(_ config: EZTransitionConfig){
        config._toPack?.isTransiting = false
        config._toPack?.completedOpenAction()
    }
    
    
    //MARK: - Instead
    @MainActor
    static private func transitInstead(_ config: EZTransitionConfig) -> (any EZUIPacProtocol)?{
        if !checkValid(config) { return nil }
        
        config._animation.build { $0
            .setPacks{$0
                .fromPack(config._fromPack)
                .toPack(config._toPack)
            }
            .setActions{$0
                .prepareAction { prepareInstead(config) }
                .animationAction { animationInstead(config) }
                .completionAction { completionInstead(config) }
            }
        }.animate()
    
        return config._toPack
    }
    
    @MainActor
    static private func prepareInstead(_ config: EZTransitionConfig){
        config._fromPack?.isTransiting = true
        config._toPack?.isTransiting = true
        if let archivedPack = config._archivedPack{
            config._toPack?.archived = archivedPack
        }
        
        if let pack = config._toPack{
            (config._toLine ?? config._fromPack?.line)?.setPack(pack)
        }
        setChildInstead(config)
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
        rotateInstead(config)
#endif
        useStartActions(config)
        config._fromPack?.closeAction()
    }
    
    @MainActor
    static private func animationInstead(_ config: EZTransitionConfig){
        config._toPack?.openWithAnimationAction()
        config._fromPack?.closeWithAnimationAction()
    }
    
    @MainActor
    static private func completionInstead(_ config: EZTransitionConfig){
        config._fromPack?.isTransiting = false
        config._toPack?.isTransiting = false
        config._toPack?.completedOpenAction()
        config._fromPack?.completedCloseAction()
        removeFromParent(config)
        config._toPack?.window?.updateRootPack()
    }
    
    //MARK: - Metods
#if targetEnvironment(macCatalyst)
    @MainActor
    static private func transitWindow(_ config: EZTransitionConfig) -> (any EZUIPacProtocol)?{
        guard let toPack = config._toPack else { return nil }
        EZUIPacWindow.needToPerform = .init(toPack)
        if let pack = config._toPack{ config._toLine?.setPack(pack) }
        UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil, errorHandler: nil)
        return toPack
    }
#endif

    @MainActor
    private static func checkValid(_ config: EZTransitionConfig) -> Bool{
        config._fromPack != nil &&
        config._fromPack !== config._toPack &&
        !config._safe ||
        (
            config._fromPack?.router.stateStorage.isTransiting == false &&
            (config._toPack == nil || config._toPack?.router.stateStorage.isTransiting == false)
        )
    }

    @MainActor
    private static func setChildIn(_ config: EZTransitionConfig){
        guard let toPack = config._toPack, let fromPack = config._fromPack else { return }
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
        toPack.container.autoResizeParentOnRotation = config._autoResizeContainerOnRotation
#endif
        setupContainer(config._container ?? fromPack.ezController.view, toPack.container)
        setChild(fromPack, toPack)
    }
    
    @MainActor
    private static func setChildInstead(_ config: EZTransitionConfig){
        guard let toPack = config._toPack else { return }
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
        toPack.container.autoResizeParentOnRotation = config._fromPack?.container.autoResizeParentOnRotation ?? false
        if #available(iOS 16.0, *) {
            config._fromPack?.window?.windowScene?.requestGeometryUpdate(
                .iOS(interfaceOrientations: toPack.ezController.supportedInterfaceOrientations)
            )
        }
#endif
        toPack.window = config._fromPack?.window
        config._fromPack?.window = nil
        if let parent = config._fromPack?.parent{ setChild(parent, toPack) }
        setupContainer(config._fromPack?.container.superview, toPack.container)
    }
    
    @MainActor
    private static func setChild(
        _ parent: any EZUIPacProtocol,
        _ child: any EZUIPacProtocol
    ){
        parent.addChild(pack: child)
        setChild(parent.ezController, child.ezController)
    }
    
    @MainActor
    private static func setChild(
        _ child: any EZUIPacProtocol,
        _ container: EZView?
    ){
        setupContainer(container, child.container)
    }
    
    @MainActor
    private static func setChild(_ parent: EZViewController, _ child: EZViewController){
        child.willMove(toParent: parent)
        parent.addChild(child)
#if canImport(UIKit)
        child.didMove(toParent: parent)
#endif
    }
    
    @MainActor
    private static func setupContainer(_ container: EZView?, _ childView: EZContainerView){
        container?.addSubview(childView)
    }
    
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    @MainActor
    private static func rotateIn(_ config: EZTransitionConfig){
        guard let toPack = config._toPack, let fromPack = config._fromPack else { return }
        rotate(fromPack.currentOrientation, fromPack.rootWindow?.interfaceOrientation, toPack)
    }
    
    @MainActor
    private static func rotateInstead(_ config: EZTransitionConfig){
        guard let toPack = config._toPack else { return }
        if let parent = config._fromPack?.parent{
            rotate(parent.currentOrientation, parent.rootWindow?.interfaceOrientation, toPack)
        }else{
            rotate(
                config._toPack?.rootWindow?.interfaceOrientation,
                config._toPack?.rootWindow?.interfaceOrientation,
                toPack
            )
        }
    }
    
    @MainActor
    private static func rotate(
        _ parentOrientation: UIInterfaceOrientation?,
        _ windowOrientation: UIInterfaceOrientation?,
        _ pack: any EZUIPacProtocol
    ){
        let orientation = windowOrientation ?? parentOrientation ?? .portrait
        EZUIPacRotateController.rotateAll(pack: pack, newOrientation: orientation)
    }
#endif
    
    @MainActor
    private static func useStartActions(_ config: EZTransitionConfig){
        config._toPack?.startAction()
        config._toPack?.openAction()
    }
    
    @MainActor
    private static func removeFromParent(_ config: EZTransitionConfig){
        config._fromPack?.removeFromParent()
        config._fromPack?.container.removeFromSuperview()
        removeFromParent(config._fromPack?.ezController)
        
        
        config._fromPack?.container.transform = .init(scaleX: 1, y: 1)
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
        config._fromPack?.currentOrientation = nil
#endif
    }
    
    @MainActor
    private static func removeFromParent(_ ezController: EZViewController?){
#if canImport(UIKit)
        ezController?.willMove(toParent: nil)
#endif
        ezController?.removeFromParent()
        ezController?.didMove(toParent: nil)
    }
#endif
}
