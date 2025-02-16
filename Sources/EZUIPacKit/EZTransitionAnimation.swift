//
//  File.swift
//  
//
//  Created by Александр Сенин on 02.06.2023.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif
#if canImport(EZBuilderKit)
import EZBuilderKit
#endif

#if canImport(UIKit) ||  canImport(Cocoa)
public struct EZTransitionAnimationModel<Config: EZTransitionConfigProtocol>{
    public var config: Config
    
    public var animationAction: () -> () = {}
    public var completionAction: () -> () = {}
}

extension EZTransitionAnimationModel where Config == EZInTransitionConfig{
    public var fromView: EZView { config._fromPack.ezController.view }
    public var toView: EZView { config._toPack.ezController.view }
    public var foundation: EZView? { toView.superview }
}


public struct EZTransitionAnimation<Config: EZTransitionConfigProtocol>: EZBuildableProtocol{
    public typealias AnimationAction = (
        _ model: EZTransitionAnimationModel<Config>
    ) -> ()

    private var animation: AnimationAction?
    
    public func animate(
        config: Config,
        prepareAction: @escaping () -> () = {},
        animationAction: @escaping () -> () = {},
        completionAction: @escaping () -> () = {}
    ){
        let model = EZTransitionAnimationModel(
            config: config, 
            animationAction: animationAction,
            completionAction: completionAction
        )
        prepareAction()
        if let animation {
            animation(model)
        }else {
            model.animationAction()
            model.completionAction()
        }
    }
    
    public init(animation: @escaping AnimationAction) {
        self.animation = animation
    }
    
    public init(){}
}


extension EZTransitionAnimation where Config == EZInTransitionConfig{
//    public static var ezAnim: Self{
//        .init{ model in
//            let rootSize = model.foundation?.frame.size ?? .zero
//            model.toView?.transform.ty += rootSize.height
//            UIView.animate(
//                withDuration: 0.6,
//                delay: 0.0,
//                usingSpringWithDamping: 1,
//                initialSpringVelocity: 0,
//                options: [.curveEaseInOut],
//                animations:{
//                    model.toView?.transform.ty = 0
//                    model.fromView?.transform.ty -= rootSize.height * 0.3
//                    model.animationAction()
//                }
//            ){_ in
//                model.fromView?.transform.ty = 0
//                model.completionAction()
//            }
//        }
//    }
    
    public static var ezAnim: Self{
        .init{ model in
            let rootSize = model.foundation?.frame.size ?? .zero
            model.toView.transform.ty += rootSize.height
            UIView.animate(
                withDuration: 0.6,
                delay: 0.0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: 0,
                options: [.curveEaseInOut],
                animations:{
                    model.toView.transform.ty = 0
                    model.animationAction()
                }
            ){_ in
                model.completionAction()
            }
        }
    }
}

#endif

