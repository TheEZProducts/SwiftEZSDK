//
//  EZTabBarTransition.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

extension EZTransition<UIViewController>{
    public func tabBarSet(_ controllers: [UIViewController]) -> EZTabBarSetTransition {
        .init(container: container, controllers: controllers)
    }
    
    public func tabBarSet(_ controller: UIViewController) -> EZTabBarSetTransition {
        .init(container: container, controllers: [controller])
    }
    
    public func tabBarSelect(_ controller: UIViewController) -> EZTabBarSelectControllerTransition {
        .init(container: container, controller: controller)
    }
    
    public func tabBarSelect(_ index: Int) -> EZTabBarSelectIndexTransition {
        .init(container: container, index: index)
    }
    
    public func tabBarNext() -> EZTabBarNextTransition {
        .init(container: container)
    }
    
    public func tabBarBack() -> EZTabBarBackTransition {
        .init(container: container)
    }
    
    public func tabBarReplace(_ controller: UIViewController) -> EZTabBarReplaceTransition {
        .init(container: container, controller: controller)
    }
}

protocol EZTabBarTransitionProtocol: EZTransitionProtocol<EZChildTransitionContext>{}

//MARK: - EZTabBarSetTransition
public struct EZTabBarSetTransition: EZTabBarTransitionProtocol{
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
            let tabBarController = (container as? UITabBarController) ?? container.tabBarController
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.setViewControllers(controllers, animated: context._animate)
            if let transitionCoordinator = tabBarController.transitionCoordinator{
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

//MARK: - EZTabBarSetIndexTransition
public struct EZTabBarSelectIndexTransition: EZTabBarTransitionProtocol{
    private var container: UIViewController
    private var index: Int
    
    public var context = EZChildTransitionContext()
    
    public init(container: UIViewController, index: Int) {
        self.container = container
        self.index = index
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let tabBarController = (container as? UITabBarController) ?? container.tabBarController
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.selectedIndex = index
            if let transitionCoordinator = tabBarController.transitionCoordinator{
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

//MARK: - EZTabBarNextTransition
public struct EZTabBarNextTransition: EZTabBarTransitionProtocol {
    private var container: UIViewController
    
    public var context = EZChildTransitionContext()
    
    public init(container: UIViewController) {
        self.container = container
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let tabBarController = (container as? UITabBarController) ?? container.tabBarController,
            (tabBarController.selectedIndex + 1) < tabBarController.viewControllers?.count ?? 0
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map { context._interactive?($0) }
            tabBarController.selectedIndex += 1
            if let transitionCoordinator = tabBarController.transitionCoordinator{
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

//MARK: - EZTabBarBackTransition
public struct EZTabBarBackTransition: EZTabBarTransitionProtocol{
    private var container: UIViewController
    
    public var context = EZChildTransitionContext()
    
    public init(container: UIViewController) {
        self.container = container
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let tabBarController = (container as? UITabBarController) ?? container.tabBarController,
            (tabBarController.selectedIndex - 1) >= 0
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.selectedIndex -= 1
            if let transitionCoordinator = tabBarController.transitionCoordinator{
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

//MARK: - EZTabBarSelectControllerTransition
public struct EZTabBarSelectControllerTransition: EZTabBarTransitionProtocol{
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
            let tabBarController = (container as? UITabBarController) ?? container.tabBarController,
            let index = tabBarController.viewControllers?.firstIndex(of: controller)
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil ||
            controller.transitionCoordinator != nil
        { return false }
        
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.selectedIndex = index
            if let transitionCoordinator = tabBarController.transitionCoordinator{
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

//MARK: - EZTabBarReplaceTransition
public struct EZTabBarReplaceTransition: EZReplaceTransitionProtocol, EZTabBarTransitionProtocol{
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
            let tabBarController = container.tabBarController
        else { return false }
        
        if
            !context._unsafeTransition,
            container.transitionCoordinator != nil
        { return false }
        
        if let index = tabBarController.viewControllers?.firstIndex(of: controller){
            indexTransit(
                tabBarController: tabBarController,
                index: index
            )
        }else if
            let controllers = tabBarController.viewControllers,
            tabBarController.selectedIndex < controllers.count
        {
            replaceTransit(
                tabBarController: tabBarController,
                controllers: controllers
            )
        }else{ return false }
        
        return true
    }
    
    @MainActor
    private func indexTransit(
        tabBarController: UITabBarController,
        index: Int
    ) {
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.selectedIndex = index
            if let transitionCoordinator = tabBarController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
    }
    
    @MainActor
    private func replaceTransit(
        tabBarController: UITabBarController,
        controllers: [UIViewController]
    ) {
        var controllers = controllers
        controllers[tabBarController.selectedIndex] = controller
        tabBarController.wrappDelegateForChildTransition(
            animation: context._animation,
            interactive: context._interactive != nil
        ) { animator in
            animator.map{ context._interactive?($0) }
            tabBarController.setViewControllers(controllers, animated: context._animate)
            if let transitionCoordinator = tabBarController.transitionCoordinator{
                transitionCoordinator.animate(
                    alongsideTransition: nil,
                    completion: {_ in context._completion?() }
                )
            }else{
                context._completion?()
            }
        }
    }
}
#endif
