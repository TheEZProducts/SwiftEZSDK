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
public struct EZTransitionAnimationModel{
    public var fromPack: (any EZUIPacProtocol)?
    public var toPack: (any EZUIPacProtocol)?
    
    public var fromView: EZView? { fromPack?.controller.view }
    public var toView: EZView? { toPack?.controller.view }
    public var foundation: EZView? { toView?.superview }
    
    public var animationAction: () -> () = {}
    public var completionAction: () -> () = {}
}


public struct EZTransitionAnimation: EZBuildableProtocol{
    public typealias AnimationAction = (
        _ model: EZTransitionAnimationModel
    ) -> ()

    private var animation: AnimationAction?
    public fileprivate(set) var prepareAction: () -> () = {}
    public fileprivate(set) var model = EZTransitionAnimationModel()
    
    public func animate(){
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

#if canImport(EZBuilderKit)
extension EZBuilder<EZTransitionAnimation>{
    @discardableResult
    func setPacks(_ action: (Pack) -> ()) -> Self { use(action) }
    class Pack: EZBuilder{
        @discardableResult
        public func fromPack(_ pack: (any EZUIPacProtocol)?) -> Self{
            value.model.fromPack = pack
            return self
        }
        
        @discardableResult
        public func toPack(_ pack: (any EZUIPacProtocol)?) -> Self{
            value.model.toPack = pack
            return self
        }
    }

    @discardableResult
    func setActions(_ action: (Action) -> ()) -> Self { use(action) }
    class Action: EZBuilder{
        @discardableResult
        public func prepareAction(_ action: @escaping () -> ()) -> Self{
            value.prepareAction = action
            return self
        }

        @discardableResult
        public func animationAction(_ action: @escaping () -> ()) -> Self{
            value.model.animationAction = action
            return self
        }

        @discardableResult
        public func completionAction(_ action: @escaping () -> ()) -> Self{
            value.model.completionAction = action
            return self
        }
    }
}
#endif

extension EZTransitionAnimation{
    public static var ezAnim: Self{
        .init{ model in
            let rootSize = model.foundation?.frame.size ?? .zero
            model.toView?.transform.ty += rootSize.height
            UIView.animate(
                withDuration: 0.6,
                delay: 0.0,
                usingSpringWithDamping: 1,
                initialSpringVelocity: 0,
                options: [.curveEaseInOut],
                animations:{
                    model.toView?.transform.ty = 0
                    model.fromView?.transform.ty -= rootSize.height * 0.3
                    model.animationAction()
                }
            ){_ in
                model.fromView?.transform.ty = 0
                model.completionAction()
            }
        }
    }
}

#endif
