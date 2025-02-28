//
//  EZNavigationTransition.swift
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
    public func navigationPush(_ controller: UIViewController) -> EZNavigationPushTransition {
        .init(container: container, controller: controller)
    }
    
    public func navigationPop() -> EZNavigationPopTransition {
        .init(container: container)
    }
    
    public func navigationPopTo(_ controller: UIViewController) -> EZNavigationPopToTransition {
        .init(container: container, controller: controller)
    }
    
    public func navigationPopToRoot() -> EZNavigationPopToRootTransition {
        .init(container: container)
    }
    
    public func navigationSet(_ controllers: [UIViewController]) -> EZNavigationSetTransition {
        .init(container: container, controllers: controllers)
    }
    
    public func navigationReplace(_ controller: UIViewController) -> EZNavigationReplaceTransition {
        .init(container: container, controller: controller)
    }
    
    public func navigationReplaceTop(_ controller: UIViewController) -> EZNavigationReplaceTopTransition {
        .init(container: container, controller: controller)
    }
}


//MARK: - EZNavigationTransitionContext
public struct EZChildTransitionContext: EZTransitionContextProtocol{
    var _unsafeTransition: Bool = false
    
    var _animate: Bool = false
    var _animation: UIViewControllerAnimatedTransitioning?
    var _completion: (() -> Void)?
    
    var _interactive: ((UIPercentDrivenInteractiveTransition) -> Void)?
}

extension EZTransitionProtocol where Context == EZChildTransitionContext{
    public func safeTransition(_ value: Bool) -> Self {
        var new = self
        new.context._unsafeTransition = !value
        return new
    }
    
    public func unsafeTransition() -> Self {
        var new = self
        new.context._unsafeTransition = true
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
    
    public func interactive(_ value: @escaping (UIPercentDrivenInteractiveTransition) -> Void) -> Self{
        var new = self
        new.context._interactive = value
        return new
    }
}

protocol EZNavigationTransitionProtocol: EZTransitionProtocol<EZChildTransitionContext>{}

@available(iOS 13.0, *)
extension EZTransitionProtocol<EZChildTransitionContext>{
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

//MARK: - EZNavigationPushTransition
public struct EZNavigationPushTransition: EZNavigationTransitionProtocol{
    private var container: UIViewController
    private var controller: UIViewController
    
    public var context = EZChildTransitionContext()
    
    public init(container: UIViewController, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            !(controller is UINavigationController),
            let navigationController = (container as? UINavigationController) ?? container.navigationController
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.pushViewController(controller, animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZNavigationPopTransition
public struct EZNavigationPopTransition: EZNavigationTransitionProtocol{
    private var container: UIViewController
    
    public var context = EZChildTransitionContext()
    
    public init(container: UIViewController) {
        self.container = container
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let navigationController = (container as? UINavigationController) ?? container.navigationController
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.popViewController(animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZNavigationPopToRootTransition
public struct EZNavigationPopToRootTransition: EZNavigationTransitionProtocol{
    private var container: UIViewController
    
    public var context = EZChildTransitionContext()
    
    public init(container: UIViewController) {
        self.container = container
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let navigationController = (container as? UINavigationController) ?? container.navigationController
        else { return false }
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.popToRootViewController(animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZNavigationPopToTransition
public struct EZNavigationPopToTransition: EZNavigationTransitionProtocol{
    private var container: UIViewController
    private var controller: UIViewController
    
    public var context = EZChildTransitionContext()
    
    public init(container: UIViewController, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            !(controller is UINavigationController),
            let navigationController = (container as? UINavigationController) ?? container.navigationController
        else { return false }
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.popToViewController(controller, animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZNavigationSetTransition
public struct EZNavigationSetTransition: EZNavigationTransitionProtocol{
    private var container: UIViewController
    private var controllers: [UIViewController]
    
    public var context = EZChildTransitionContext()
    
    public init(container: UIViewController, controllers: [UIViewController]) {
        self.container = container
        self.controllers = controllers
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            controllers.first(where: { $0 is UINavigationController }) == nil,
            let navigationController = (container as? UINavigationController) ?? container.navigationController
        else { return false }
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.setViewControllers(controllers, animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZNavigationReplaceTransition
public struct EZNavigationReplaceTransition: EZReplaceTransitionProtocol, EZNavigationTransitionProtocol{
    private var container: UIViewController
    private var controller: UIViewController
    
    public var context = EZChildTransitionContext()
    
    public init(container: UIViewController, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            !(controller is UINavigationController),
            let navigationController = container.navigationController,
            let index = navigationController.viewControllers.firstIndex(of: container)
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        
        var controllers = navigationController.viewControllers
        controllers[index] = controller
        
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.setViewControllers(controllers, animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}

//MARK: - EZNavigationReplaceTransition
public struct EZNavigationReplaceTopTransition: EZTransitionProtocol, EZNavigationTransitionProtocol{
    private var container: UIViewController
    private var controller: UIViewController
    
    public var context = EZChildTransitionContext()
    
    public init(container: UIViewController, controller: UIViewController) {
        self.container = container
        self.controller = controller
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            !(controller is UINavigationController),
            let navigationController = (container as? UINavigationController) ?? container.navigationController,
            let topController = navigationController.topViewController,
            let index = navigationController.viewControllers.firstIndex(of: topController)
        else { return false }
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        if
            !context._unsafeTransition,
            navigationController.transitionCoordinator != nil
        { return false }
        
        var controllers = navigationController.viewControllers
        controllers[index] = controller
        
        navigationController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            navigationController.setViewControllers(controllers, animated: context._animate)
            if let transitionCoordinator = navigationController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
        return true
    }
}
