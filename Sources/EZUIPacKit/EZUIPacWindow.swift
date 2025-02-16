//
//  File.swift
//  
//
//  Created by Александр Сенин on 08.06.2023.
//

import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

#if canImport(UIKit)
public typealias EZWindow = UIWindow
#elseif canImport(Cocoa)
public typealias EZWindow = NSWindow
#endif

enum EZUIPacWrapper{
    case line(EZUIPacLine)
    case pack(any EZUIPacProtocol)
    
    var pack: any EZUIPacProtocol{
        switch self{
            case let .line(line): return line.currentPack
            case let .pack(pack): return pack
        }
    }
}


#if canImport(UIKit) || canImport(Cocoa)
open class EZUIPacWindow: EZWindow{
    @MainActor
    public static var needToPerform: EZUIPacLine?
    
//    @MainActor
    public var rootUIPac: (any EZUIPacProtocol)? { rootLine?.currentPack }
    
    @MainActor
    public var rootLine: EZUIPacLine?//{
//        didSet(old){
//            if rootUIPac == nil{
//#if targetEnvironment(macCatalyst)
//                closePacks(old)
//                close()
//#endif
//            }else{
//                old?.window = nil
//                rootViewController = rootUIPac?.controller
//                rootUIPac?.window = self
//            }
//        }
//    }
    
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    lazy open var interfaceOrientation: UIInterfaceOrientation = getInterfaceOrientation()
    private var orientationKey: NSKeyValueObservation?
#endif
    
    @available(iOS 13.0, *)
    @MainActor
    override public init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        setup()
    }
    
    @MainActor
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
        
    @MainActor
    open func setup(){
        setupPack()
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
        let action = {[weak self] in self?.orientationChanged() }
        orientationKey = observe(\.frame, options: [.old, .new]) {_, _ in action()}
#endif
        rootUIPac?.startAction()
        rootUIPac?.openAction()
        rootUIPac?.openWithAnimationAction()
        rootUIPac?.completedOpenAction()
    }
    
    @MainActor
    open func setupPack(){
        guard let line = Self.needToPerform else { return }
        Self.needToPerform = nil
        rootLine = line
//        rootViewController = rootUIPac?.controller
//        rootUIPac?.window = self
        updateRootPack()
        
        
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
        interfaceOrientation = line.currentPack.ezController.preferredInterfaceOrientationForPresentation
        rotatePacks(newOrientation: interfaceOrientation)
#endif
    }
    
    open func updateRootPack(){
        rootUIPac?.container.removeFromSuperview()
        rootViewController = self.rootUIPac?.ezController
        makeKeyAndVisible()
    }
    
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    private func orientationChanged() {
        let newOrientation = getInterfaceOrientation()
        if interfaceOrientation == newOrientation{ return }
        let oldOrientation = interfaceOrientation
        interfaceOrientation = newOrientation
        rotatePacks(oldOrientation: oldOrientation, newOrientation: interfaceOrientation)
    }
    
    private func rotatePacks(oldOrientation: UIInterfaceOrientation? = nil, newOrientation: UIInterfaceOrientation){
        if let rootUIPac{
            EZUIPacRotateController.rotateAll(
                pack: rootUIPac,
                oldOrientation: oldOrientation,
                newOrientation: newOrientation
            )
        }
    }
    
    private func getInterfaceOrientation() -> UIInterfaceOrientation{
        if #available(iOS 13.0, *){
            return windowScene?.interfaceOrientation ?? .portrait
        }else{
            return UIApplication.shared.statusBarOrientation
        }
    }
#endif
    
#if targetEnvironment(macCatalyst)
    @objc
    open func close(){
        guard let windowScene else { return }
        UIApplication.shared.requestSceneSessionDestruction(
            windowScene.session,
            options: nil,
            errorHandler: nil
        )
    }
#endif
    
    private func closePacks(_ pack: (any EZUIPacProtocol)?){
//        pack?.forEachAtPacksTree{
//            $0.closeAction()
//            $0.closeWithAnimationAction()
//            $0.completedCloseAction()
//        }
    }
    
    deinit{ closePacks(rootUIPac) }
    
    @MainActor
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
