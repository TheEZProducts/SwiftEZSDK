//
//  Untitled.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

import UIKit

extension UIViewControllerAnimatedTransitioning where Self == EZOpenAnimation{
    public static var ezOpen: Self { .init() }
    public static func ezOpen(
        direction: EZAnimationDirection = .up,
        duration: TimeInterval = 0.5
    ) -> Self { .init(direction: direction, duration: duration) }
}

public enum EZAnimationDirection{
    case up
    case down
    case right
    case left
}

public class EZOpenAnimation: NSObject, UIViewControllerAnimatedTransitioning{
    public var duration: TimeInterval = 0.5
    public var direction: EZAnimationDirection = .up
    
    
    init(direction: EZAnimationDirection = .up, duration: TimeInterval? = nil){
        self.direction = direction
        if let duration { self.duration = duration }
    }
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let toViewC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        let fromView = transitionContext.view(forKey: .from)
        let container = transitionContext.containerView
        container.addSubview(toViewC.view)
        toViewC.view.frame = transitionContext.finalFrame(for: toViewC)
        
        preparePosition(toView: toViewC.view, container: container)
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0.0,
            options: [.curveEaseInOut]
        ) {
            toViewC.view.transform.ty = 0
            toViewC.view.transform.tx = 0
            self.animatePosition(fromView: fromView, container: container)
        } completion: { _ in
            fromView?.transform.ty = 0
            fromView?.transform.tx = 0
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func preparePosition(toView: UIView, container: UIView){
        switch direction {
        case .up:
            toView.transform.ty = container.bounds.height
        case .down:
            toView.transform.ty = -container.bounds.height
        case .right:
            toView.transform.tx = -container.bounds.width
        case .left:
            toView.transform.tx = container.bounds.width
        }
    }
    
    private func animatePosition(fromView: UIView?, container: UIView){
        switch direction {
        case .up:
            fromView?.transform.ty -= container.bounds.height * 0.3
        case .down:
            fromView?.transform.ty = container.bounds.height * 0.3
        case .right:
            fromView?.transform.tx = container.bounds.width * 0.3
        case .left:
            fromView?.transform.tx -= container.bounds.width * 0.3
        }
    }
}

extension UIViewControllerAnimatedTransitioning where Self == EZCloseAnimation{
    public static var ezClose: Self { .init() }
    public static func ezClose(
        direction: EZAnimationDirection = .up,
        duration: TimeInterval = 0.5
    ) -> Self { .init(direction: direction, duration: duration) }
}

public class EZCloseAnimation: NSObject, UIViewControllerAnimatedTransitioning{
    public var duration: TimeInterval = 0.5
    public var direction: EZAnimationDirection = .up
    
    init(direction: EZAnimationDirection = .up, duration: TimeInterval? = nil){
        self.direction = direction
        if let duration { self.duration = duration }
    }
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromViewC = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        let toView = transitionContext.view(forKey: .to)
        let container = transitionContext.containerView
        if let toView{
            container.addSubview(toView)
            container.bringSubviewToFront(fromViewC.view)
        }
       
        preparePosition(toView: toView, container: container)
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseInOut]
        ){
            self.animatePosition(fromView: fromViewC.view, container: container)
            toView?.transform.ty = 0
            toView?.transform.tx = 0
        } completion: {_ in
            fromViewC.view.transform.ty = 0
            fromViewC.view.transform.tx = 0
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func preparePosition(toView: UIView?, container: UIView){
        switch direction {
        case .up:
            toView?.transform.ty -= container.bounds.height * 0.3
        case .down:
            toView?.transform.ty = container.bounds.height * 0.3
        case .right:
            toView?.transform.tx = container.bounds.width * 0.3
        case .left:
            toView?.transform.tx -= container.bounds.width * 0.3
        }
    }
    
    private func animatePosition(fromView: UIView, container: UIView){
        switch direction {
        case .up:
            fromView.transform.ty += container.bounds.height
        case .down:
            fromView.transform.ty -= container.bounds.height
        case .right:
            fromView.transform.tx -= container.bounds.width
        case .left:
            fromView.transform.tx += container.bounds.width
        }
    }
}


extension UIViewControllerAnimatedTransitioning where Self == EZAppearanceAnimation{
    public static var ezAppearance: Self { .init() }
    public static func ezAppearance(duration: TimeInterval) -> Self { .init(duration: duration) }
}

public class EZAppearanceAnimation: NSObject, UIViewControllerAnimatedTransitioning{
    public var duration: TimeInterval = 0.2
    init(duration: TimeInterval? = nil){
        if let duration { self.duration = duration }
    }
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let toViewC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        let container = transitionContext.containerView
        container.addSubview(toViewC.view)
        toViewC.view.frame = transitionContext.finalFrame(for: toViewC)
        toViewC.view.alpha = 0
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext)
        ) {
            toViewC.view.alpha = 1
        } completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

extension UIViewControllerAnimatedTransitioning where Self == EZDisappearanceAnimation{
    public static var ezDisappearance: Self { .init() }
    public static func ezDisappearance(duration: TimeInterval) -> Self { .init(duration: duration) }
}

public class EZDisappearanceAnimation: NSObject, UIViewControllerAnimatedTransitioning{
    public var duration: TimeInterval = 0.2
    init(duration: TimeInterval? = nil){
        if let duration { self.duration = duration }
    }
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromViewC = transitionContext.viewController(forKey: .from) else {
            transitionContext.completeTransition(false)
            return
        }
        let toView = transitionContext.view(forKey: .to)
        let container = transitionContext.containerView
        if let toView{
            container.addSubview(toView)
            container.bringSubviewToFront(fromViewC.view)
        }
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: [.curveEaseInOut]
        ){
            fromViewC.view.alpha = 0
        } completion: {_ in
            fromViewC.view.alpha = 1
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

extension UIViewControllerAnimatedTransitioning where Self == EZShiftAnimation{
    public static func ezShift(
        direction: EZAnimationDirection,
        duration: TimeInterval = 0.5
    ) -> Self { .init(direction: direction, duration: duration) }
}

public class EZShiftAnimation: NSObject, UIViewControllerAnimatedTransitioning{
    public var duration: TimeInterval = 0.5
    public var direction: EZAnimationDirection = .left
    
    
    init(direction: EZAnimationDirection = .up, duration: TimeInterval? = nil){
        self.direction = direction
        if let duration { self.duration = duration }
    }
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        duration
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let toViewC = transitionContext.viewController(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        let fromView = transitionContext.view(forKey: .from)
        let container = transitionContext.containerView
        container.addSubview(toViewC.view)
        toViewC.view.frame = transitionContext.finalFrame(for: toViewC)
        
        preparePosition(toView: toViewC.view, container: container)
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0.0,
            options: [.curveEaseInOut]
        ) {
            toViewC.view.transform.ty = 0
            toViewC.view.transform.tx = 0
            self.animatePosition(fromView: fromView, container: container)
        } completion: { _ in
            fromView?.transform.ty = 0
            fromView?.transform.tx = 0
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
    
    private func preparePosition(toView: UIView, container: UIView){
        switch direction {
        case .up:
            toView.transform.ty = container.bounds.height
        case .down:
            toView.transform.ty = -container.bounds.height
        case .right:
            toView.transform.tx = -container.bounds.width
        case .left:
            toView.transform.tx = container.bounds.width
        }
    }
    
    private func animatePosition(fromView: UIView?, container: UIView){
        switch direction {
        case .up:
            fromView?.transform.ty -= container.bounds.height
        case .down:
            fromView?.transform.ty = container.bounds.height
        case .right:
            fromView?.transform.tx = container.bounds.width
        case .left:
            fromView?.transform.tx -= container.bounds.width
        }
    }
}


//public static var shiftLeft: RZTransitionAnimation{
//    RZTransitionAnimation("shiftLeft") { oldView, newView, placeView, end in
//        let rootSize = placeView.frame.size
//        if let oldView = oldView, let newView = newView{
//            newView.transform.tx += rootSize.width
//            UIView.animate(withDuration: 0.3, animations: {
//                newView.transform.tx = 0
//                oldView.transform.tx -= rootSize.width
//            }){_ in
//                oldView.transform.tx = 0
//                end()
//            }
//        }
//    }
//}
//
//public static var shiftRight: RZTransitionAnimation{
//    RZTransitionAnimation("shiftRight") { oldView, newView, placeView, end in
//        let rootSize = placeView.frame.size
//        if let oldView = oldView, let newView = newView{
//            newView.transform.tx -= rootSize.width
//            UIView.animate(withDuration: 0.3, animations: {
//                newView.transform.tx = 0
//                oldView.transform.tx += rootSize.width
//            }){_ in
//                oldView.transform.tx = 0
//                end()
//            }
//        }
//    }
//}
//
//public static var shiftLeftEz: RZTransitionAnimation{
//    RZTransitionAnimation("shiftLeftEz") { oldView, newView, placeView, end in
//        let rootSize = placeView.frame.size
//        if let oldView = oldView, let newView = newView{
//            newView.transform.tx += rootSize.width
//            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
//                newView.transform.tx = 0
//                oldView.transform.tx -= rootSize.width
//            }){_ in
//                oldView.transform.tx = 0
//                end()
//            }
//        }
//    }
//}
//
//public static var shiftRightEz: RZTransitionAnimation{
//    RZTransitionAnimation("shiftRightEz") { oldView, newView, placeView, end in
//        let rootSize = placeView.frame.size
//        if let oldView = oldView, let newView = newView{
//            newView.transform.tx -= rootSize.width
//            UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: {
//                newView.transform.tx = 0
//                oldView.transform.tx += rootSize.width
//            }){_ in
//                oldView.transform.tx = 0
//                end()
//            }
//        }
//    }
//}
