//
//  EZUITabBarControllerDelegate.swift
//  UIPackkages
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

open class EZUITabBarControllerDelegate: NSObject, UITabBarControllerDelegate{
    public weak var delegate: UITabBarControllerDelegate?
    
    public var animation: (any UIViewControllerAnimatedTransitioning)?
    public var interactive: UIPercentDrivenInteractiveTransition?
    
    public init(
        delegate: UITabBarControllerDelegate?,
        animation: (any UIViewControllerAnimatedTransitioning)? = nil,
        interactive: UIPercentDrivenInteractiveTransition? = nil
    ) {
        self.delegate = delegate
        self.animation = animation
        self.interactive = interactive
    }
    
    @available(iOS 18.0, tvOS 18.0, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelectTab tab: UITab
    ) -> Bool{
        delegate?.tabBarController?(
            tabBarController,
            shouldSelectTab: tab
        ) ?? true
    }
    
    
    @available(iOS 18.0, tvOS 18.0, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        didSelectTab selectedTab: UITab,
        previousTab: UITab?
    ){
        delegate?.tabBarController?(
            tabBarController,
            didSelectTab: selectedTab,
            previousTab: previousTab
        )
    }
#if !os(tvOS)
    @available(iOS 18.0, tvOS 18.0, *)
    open func tabBarControllerWillBeginEditing(_ tabBarController: UITabBarController){
        delegate?.tabBarControllerWillBeginEditing?(tabBarController)
    }
    
    
    @available(iOS 18.0, tvOS 18.0, *)
    open func tabBarControllerDidEndEditing(_ tabBarController: UITabBarController){
        delegate?.tabBarControllerDidEndEditing?(tabBarController)
    }
    
    
    @available(iOS 18.0, tvOS 18.0, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        visibilityDidChangeFor tabs: [UITab]
    ){
        delegate?.tabBarController?(
            tabBarController,
            visibilityDidChangeFor: tabs
        )
    }
    
    @available(iOS 18.0, tvOS 18.0, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        displayOrderDidChangeFor group: UITabGroup
    ){
        delegate?.tabBarController?(
            tabBarController,
            displayOrderDidChangeFor: group
        )
    }
    
    @available(iOS 18.0, tvOS 18.0, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        displayedViewControllersFor tab: UITab,
        proposedViewControllers: [UIViewController]
    ) -> [UIViewController] {
        delegate?.tabBarController?(
            tabBarController,
            displayedViewControllersFor: tab,
            proposedViewControllers: proposedViewControllers
        ) ?? proposedViewControllers
    }
#endif
    @available(iOS 3.0, macCatalyst 13.1, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        shouldSelect viewController: UIViewController
    ) -> Bool {
        delegate?.tabBarController?(
            tabBarController,
            shouldSelect: viewController
        ) ?? true
    }
    
    @available(macCatalyst 13.1, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        didSelect viewController: UIViewController
    ){
        delegate?.tabBarController?(
            tabBarController,
            didSelect: viewController
        )
    }
    
#if !os(tvOS) && !os(visionOS)
    @available(iOS 3.0, macCatalyst 13.1, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        willBeginCustomizing viewControllers: [UIViewController]
    ){
        delegate?.tabBarController?(
            tabBarController,
            willBeginCustomizing: viewControllers
        )
    }
    
    @available(iOS 3.0, macCatalyst 13.1, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        willEndCustomizing viewControllers: [UIViewController],
        changed: Bool
    ){
        delegate?.tabBarController?(
            tabBarController,
            willEndCustomizing: viewControllers,
            changed: changed
        )
    }
    
    @available(macCatalyst 13.1, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        didEndCustomizing viewControllers: [UIViewController],
        changed: Bool
    ){
        delegate?.tabBarController?(
            tabBarController,
            didEndCustomizing: viewControllers,
            changed: changed
        )
    }
#endif
    
#if !os(visionOS)
    @available(iOS 7.0, macCatalyst 13.1, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        interactive ?? delegate?.tabBarController?(
            tabBarController,
            interactionControllerFor: animationController
        )
    }
    
    @available(iOS 7.0, macCatalyst 13.1, *)
    open func tabBarController(
        _ tabBarController: UITabBarController,
        animationControllerForTransitionFrom fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)?{
        animation ?? delegate?.tabBarController?(
            tabBarController,
            animationControllerForTransitionFrom: fromVC,
            to: toVC
        ) ?? {
            guard let pac = tabBarController as? (any EZUITabBarPackProtocol) else { return nil }
            return pac.defaultChildrenTransitionAnimation
        }()
    }
#endif
}

#endif
