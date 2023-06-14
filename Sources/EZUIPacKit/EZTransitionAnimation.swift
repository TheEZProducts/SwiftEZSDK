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

#if canImport(UIKit) ||  canImport(Cocoa)
public struct EZTransitionAnimation{
    public typealias ViewAnimationAction = (
        _ fromView: EZView?,
        _ toView: EZView?,
        _ foundation: EZView,
        _ additionalAnimation: @escaping ()->(),
        _ completion: @escaping ()->()
    ) -> ()
    
    public typealias PackAnimationAction = (
        _ fromPack: (any EZUIPacProtocol)?,
        _ toPack: (any EZUIPacProtocol)?,
        _ foundation: EZView,
        _ additionalAnimation: @escaping ()->(),
        _ completion: @escaping ()->()
    ) -> ()
    
    private var animation: PackAnimationAction?
    
    public func animate(
        fromPack: (any EZUIPacProtocol)?,
        toPack: (any EZUIPacProtocol)?,
        foundation: EZView,
        additionalAnimation: @escaping ()->() = {},
        completion: @escaping ()->() = {}
    ){
        if let animation{
            animation(fromPack, toPack, foundation, additionalAnimation, completion)
        }else{
            additionalAnimation()
            completion()
        }
    }
    
    public init(animation: @escaping PackAnimationAction) {
        self.animation = animation
    }
    
    public init(animation: @escaping ViewAnimationAction) {
        self.animation = {fromPack, toPack, foundation, additionalAnimation, completion in
            animation(
                fromPack?.controller.view,
                toPack?.controller.view,
                foundation,
                additionalAnimation,
                completion
            )
        }
    }
    
    public init(){}
}

extension EZTransitionAnimation{
    public static var ezAnim: Self{
        .init{ fromView, toView, foundation, additionalAnimation, completion in
            let rootSize = foundation.frame.size
            if let toView = toView{
                toView.transform.ty += rootSize.height
                UIView.animate(
                    withDuration: 0.6,
                    delay: 0.0,
                    usingSpringWithDamping: 1,
                    initialSpringVelocity: 0,
                    options: [.curveEaseInOut],
                    animations:{
                        toView.transform.ty = 0
                        fromView?.transform.ty -= rootSize.height * 0.3
                        additionalAnimation()
                    }
                ){_ in
                    fromView?.transform.ty = 0
                    completion()
                }
            }
        }
    }
}

#endif
