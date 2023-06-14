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

#if canImport(UIKit) || canImport(Cocoa)
open class EZUIPacWindow: EZWindow{
    @MainActor
    public static var needToPerform: (any EZUIPacProtocol)?
    
    @MainActor
    public var rootUIPac: (any EZUIPacProtocol)?{
        didSet(old){
            if rootUIPac == nil{
#if targetEnvironment(macCatalyst)
                closePacks(old)
                close()
#endif
            }else{
                old?.window = nil
                rootViewController = rootUIPac?.controller
                rootUIPac?.window = self
            }
        }
    }
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
    lazy open var interfaceOrientation: UIInterfaceOrientation = getInterfaceOrientation()
    var orientationKey: NSKeyValueObservation?
#endif
    
    @available(iOS 13.0, *)
    @MainActor
    override public init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)
        canResizeToFitContent = true
        setup()
    }
    
    @MainActor
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
        
    var anim: RZAnimationAction?
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
        
        
//        if #available(macCatalyst 16.0, *) {
//            var frame: CGRect =  .zero
//            var newFrame: CGRect = .zero
//            
//        
//            self.anim = .infinityLoop(
//                .queue([
//                    .action{
//                        newFrame = .init(x: .random(in: 0...800), y: .random(in: 0...500), width: .random(in: 0...700), height: .random(in: 0...700))
//                        frame = self.windowScene?.effectiveGeometry.systemFrame ?? .zero
//                    },
//                    .animation(duration: 5, animation: {
//                        self.transitFrame(
//                            frome: frame,
//                            to: newFrame,
//                            state: $0
//                        )
//                    })
//                ])
//            )
//
//            self.anim?.start()
//            
//        }
    }
    
    func transitFrame(frome: CGRect = .zero, to: CGRect, state: CGFloat = 1){
        let f: CGRect = .init(
            x: frome.minX + (to.minX - frome.minX) * state,
            y: frome.minY + (to.minY - frome.minY) * state,
            width: frome.width + (to.width - frome.width) * state,
            height: frome.height + (to.height - frome.height) * state
        )
        if #available(macCatalyst 16.0, *) {
            self.windowScene?.requestGeometryUpdate(.Mac(systemFrame: f))
        }
    }
    
    @MainActor
    open func setupPack(){
        guard let pack = Self.needToPerform else { return }
        Self.needToPerform = nil
        rootUIPac = pack
        makeKeyAndVisible()
        
#if canImport(UIKit) && os(iOS) && !targetEnvironment(macCatalyst)
        interfaceOrientation = pack.controller.preferredInterfaceOrientationForPresentation
        rotatePacks(newOrientation: interfaceOrientation)
#endif
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
        pack?.forEachAtPacksTree{
            $0.closeAction()
            $0.closeWithAnimationAction()
            $0.completedCloseAction()
        }
    }
    
    
    deinit{
        closePacks(rootUIPac)
    }
    
    @MainActor
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
#endif
