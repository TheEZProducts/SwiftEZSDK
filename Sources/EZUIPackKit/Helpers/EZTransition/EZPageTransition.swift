//
//  EZPageTransition.swift
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
    public func pageSet(_ controllers: [UIViewController]) -> EZPageSetTransition {
        .init(container: container, controllers: controllers)
    }
}

//MARK: - EZNavigationTransitionContext
public struct EZPageTransitionContext: EZTransitionContextProtocol{
    var _unsafeTransition: Bool = false
    
    var _animate: Bool = false
    var _direction: UIPageViewController.NavigationDirection = .forward
    var _completion: (() -> Void)?
}

extension EZTransitionProtocol where Context == EZPageTransitionContext{
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
    
    public func direction(_ value: UIPageViewController.NavigationDirection) -> Self{
        var new = self
        new.context._direction = value
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
}

protocol EZPageTransitionProtocol: EZTransitionProtocol<EZPageTransitionContext>{}

@available(iOS 13.0, *)
extension EZTransitionProtocol<EZPageTransitionContext>{
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

//MARK: - EZPageSetTransition
public struct EZPageSetTransition: EZPageTransitionProtocol{
    private var container: UIViewController
    private var controllers: [UIViewController]
    
    public var context = EZPageTransitionContext()
    
    public init(container: UIViewController, controllers: [UIViewController]) {
        self.container = container
        self.controllers = controllers
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        guard
            let pageController = (container as? UIPageViewController) ?? container.pageController
        else { return false }
        pageController.setViewControllers(
            controllers,
            direction: context._direction,
            animated: context._animate,
            completion: {[completion = context._completion] _ in completion?() }
        )
        return true
    }
}
