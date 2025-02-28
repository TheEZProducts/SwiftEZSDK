//
//  EZBaseTransition.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit)
import UIKit
#elseif canImport(Cocoa)
import Cocoa
#endif

extension EZTransition<UIViewController>{
    public func present(_ controller: UIViewController) -> EZPresentTransition<Container> {
        .init(container: container, controller: controller)
    }
    
    public func dismiss() -> EZDismissTransition {
        .init(controller: container)
    }
}

extension EZTransition<EZContainerView>{
    public func present(_ controller: UIViewController) -> EZPresentTransition<Container> {
        .init(container: container, controller: controller)
    }
}

//MARK: - EZBaseTransitionContext
public struct EZBaseTransitionContext: EZTransitionContextProtocol{
    var _unsafeTransition: Bool = false
    
    var _animate: Bool = false
    var _animation: UIViewControllerAnimatedTransitioning?
    var _transitionStyle: UIModalTransitionStyle?
    var _presentationStyle: UIModalPresentationStyle?
    var _completion: (() -> Void)?
    
    var _interactive: ((UIPercentDrivenInteractiveTransition) -> Void)?
}

extension EZTransitionProtocol where Context == EZBaseTransitionContext{
    public func presentationStyle(_ value: UIModalPresentationStyle) -> Self{
        var new = self
        new.context._presentationStyle = value
        return new
    }
    
    public func animation(_ value: UIModalTransitionStyle) -> Self{
        var new = animate()
        new.context._transitionStyle = value
        return new
    }
    
    public func animation(_ value: UIViewControllerAnimatedTransitioning) -> Self{
        var new = animate()
        new.context._animation = value
        return new
    }
    
    public func animate() -> Self{
        var new = self
        new.context._animate = true
        return new
    }
    
    public func completion(_ value: @escaping () -> Void) -> Self{
        var new = self
        new.context._completion = value
        return new
    }
    
    public func unsafeTransition() -> Self{
        var new = self
        new.context._unsafeTransition = true
        return new
    }
    
    public func interactive(_ value: @escaping (UIPercentDrivenInteractiveTransition) -> Void) -> Self{
        var new = self
        new.context._interactive = value
        return new
    }
}

protocol EZBaseTransitionProtocol: EZTransitionProtocol<EZBaseTransitionContext>{}

@available(iOS 13.0, *)
extension EZTransitionProtocol<EZBaseTransitionContext>{
    @MainActor
    @discardableResult
    public func asyncTransit() async -> Bool {
        await withCheckedContinuation { continuation in
            var continuation = Optional(continuation)
            let transition = completion {[completion = context._completion] in
                completion?()
                continuation?.resume(returning: true)
                continuation = nil
            }
            if !transition.transit() {
                continuation?.resume(returning: false)
                continuation = nil
            }
        }
    }
}

//MARK: - EZPresentTransition
public struct EZPresentTransition<Container>: EZBaseTransitionProtocol{
    private var container: Container
    private var controller: UIViewController
    
    public var context = EZBaseTransitionContext()
    
    public init(container: Container, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        if let controllerTransition = self as? EZPresentTransition<UIViewController>{
            return controllerTransition.transit()
        }else if let controllerTransition = self as? EZPresentTransition<EZContainerView>{
            return controllerTransition.transit()
        }else{ return false }
    }
}

extension EZPresentTransition<UIViewController>{
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        
        controller.wrappDelegateForTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            context._transitionStyle.map{ controller.modalTransitionStyle = $0 }
            context._presentationStyle.map{ controller.modalPresentationStyle = $0 }
            container.present(controller, animated: context._animate, completion: context._completion)
        }
        return true
    }
}

extension EZPresentTransition<EZContainerView>{
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        if
            !context._unsafeTransition,
            controller.isBeingPresented || controller.isBeingDismissed
        { return false }
        controller.wrappDelegateForTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            context._transitionStyle.map{ controller.modalTransitionStyle = $0 }
            controller.modalPresentationStyle = .currentContext
            container.present(controller, animated: context._animate, completion: context._completion)
        }
        return true
    }
}

//MARK: - EZDismissTransition
public struct EZDismissTransition: EZBaseTransitionProtocol{
    private var controller: UIViewController
    
    public var context = EZBaseTransitionContext()
    
    public init(controller: UIViewController) {
        self.controller = controller
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        if
            !context._unsafeTransition,
            controller.isBeingPresented || controller.isBeingDismissed
        { return false }
        controller.rootParent.wrappDelegateForTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            context._transitionStyle.map{ controller.modalTransitionStyle = $0 }
            controller.dismiss(animated: context._animate, completion: context._completion)
        }
        return true
    }
}

extension UIViewController{
    public var rootParent: UIViewController {
        parent?.rootParent ?? self
    }
}
