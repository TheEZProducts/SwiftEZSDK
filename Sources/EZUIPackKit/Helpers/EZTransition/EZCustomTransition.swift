//
//  EZCustomTransition.swift
//  EZSDK
//
//  Created by Александр Сенин on 19.02.2025.
//

import UIKit

extension EZTransition<UIViewController>{
    public func custom() -> EZCustomTransition {
        .init(container: container)
    }
    
    public func customTo(controller: UIViewController) -> EZCustomTransition {
        .init(container: container, toController: controller)
    }
    
    public func customTo(index: Int) -> EZCustomTransition {
        .init(container: container, toIndex: index)
    }
}

extension EZTransition where Container: EZTransitionControllerProtocol{
    public func custom() -> EZCustomTransition {
        .init(transitionController: container)
    }
    
    public func customTo(controller: UIViewController) -> EZCustomTransition {
        .init(transitionController: container, toController: controller)
    }
    
    public func customTo(index: Int) -> EZCustomTransition {
        .init(transitionController: container, toIndex: index)
    }
}

@MainActor
public protocol EZTransitionControllerProtocol: AnyObject{
    @discardableResult
    func transit(context: EZCustomTransitionContext) -> Bool
}

extension EZTransitionControllerProtocol{
    public var transition: EZTransition<Self> { .init(container: self) }
}

@MainActor
public protocol EZTransitionControllerDelegateProtocol: EZTransitionControllerProtocol{}

@MainActor
public protocol EZTransitionControlledProtocol: AnyObject{
    var transitionController: EZTransitionControllerProtocol? { get set }
}

extension EZTransitionControllerProtocol where Self == EZTransitionController{
    public static func custom(
        _ action: @MainActor @escaping (_ context: EZCustomTransitionContext) -> Bool
    ) -> Self {
        .init(action)
    }
    
    public static func delegate(
        _ delegate: EZTransitionControllerDelegateProtocol
    ) -> Self {
        .init(delegate)
    }
}

open class EZTransitionController: EZTransitionControllerProtocol{
    public weak var delegate: EZTransitionControllerDelegateProtocol?
    public var action: @MainActor (_ context: EZCustomTransitionContext) -> Bool = {_ in false}
    
    public init(_ action: @MainActor @escaping (_ context: EZCustomTransitionContext) -> Bool = {_ in false}){
        self.action = action
    }
    
    public init(_ delegate: EZTransitionControllerDelegateProtocol){
        self.delegate = delegate
    }
    
    @discardableResult
    open func transit(context: EZCustomTransitionContext) -> Bool {
        delegate?.transit(context: context) ?? action(context)
    }
}

public struct EZCustomTransitionType: Equatable{
    public private(set) var key: String
    public private(set) var customData: Any?
    
    public init(key: String, customData: Any? = nil) {
        self.key = key
        self.customData = customData
    }
    
    public static func == (lhs: Self, rhs: Self) -> Bool{
        lhs.key == rhs.key
    }
}

extension EZCustomTransitionType{
    public static var ezDefault: Self { .init(key: "ezDefault") }
    public static func ezDefault(customData: Any) -> Self { .init(key: "ezDefault", customData: customData) }
    
    public static var ezToController: Self { .init(key: "ezToController") }
    public static func ezToController(customData: Any) -> Self { .init(key: "ezToController", customData: customData) }
    
    public static var ezToIndex: Self { .init(key: "ezToIndex") }
    public static func ezToIndex(customData: Any) -> Self { .init(key: "ezToIndex", customData: customData) }
    
    public static var ezNext: Self { .init(key: "ezNext") }
    public static func ezNext(customData: Any) -> Self { .init(key: "ezNext", customData: customData) }
    
    public static var ezBack: Self { .init(key: "ezBack") }
    public static func ezBack(customData: Any) -> Self { .init(key: "ezBack", customData: customData) }
    
    public static var ezSuccess: Self { .init(key: "ezSuccess") }
    public static func ezSuccess(customData: Any) -> Self { .init(key: "ezSuccess", customData: customData) }
    
    public static var ezFail: Self { .init(key: "ezFail") }
    public static func ezFail(customData: Any) -> Self { .init(key: "ezFail", customData: customData) }
    
    public static var ezOpen: Self { .init(key: "ezOpen") }
    public static func ezOpen(customData: Any) -> Self { .init(key: "ezOpen", customData: customData) }
    
    public static var ezClose: Self { .init(key: "ezClose") }
    public static func ezClose(customData: Any) -> Self { .init(key: "ezClose", customData: customData) }
}


public enum EZTransitionControllerDelegateSearchType{
    case selfDelegate
    case parent
    case hierarchy
    
    @MainActor
    public func search(to controller: UIViewController) -> EZTransitionControllerProtocol? {
        switch self {
        case .selfDelegate:
            return (controller as? EZTransitionControlledProtocol)?.transitionController
        case .parent:
            return (controller.sourceViewController as? any EZTransitionControlledProtocol)?.transitionController
        case .hierarchy:
            return controller.firstTransitionController
        }
    }
}


//MARK: - EZNavigationTransitionContext
public struct EZCustomTransitionContext: EZTransitionContextProtocol{
    public var transitionController: EZTransitionControllerProtocol?
    public var fromController: UIViewController?
    public var toController: UIViewController?
    public var toIndex: Int?
    
    public var customData: Any?
    
    public var unsafeTransition: Bool = false
    
    public var transitionType: EZCustomTransitionType = .ezDefault
    public var transitionDelegateSearchType: EZTransitionControllerDelegateSearchType = .hierarchy
    
    public var animate: Bool = false
    public var animation: UIViewControllerAnimatedTransitioning?
    public var transitionStyle: UIModalTransitionStyle?
    public var presentationStyle: UIModalPresentationStyle?
    public var completion: (() -> Void)?
}

extension EZTransitionProtocol where Context == EZCustomTransitionContext{
    public func customData(_ value: Any) -> Self {
        var new = self
        new.context.customData = value
        return new
    }
    
    public func safeTransition(_ value: Bool) -> Self {
        var new = self
        new.context.unsafeTransition = !value
        return new
    }
    
    public func unsafeTransition() -> Self {
        var new = self
        new.context.unsafeTransition = true
        return new
    }
    
    public func transitionType(_ value: EZCustomTransitionType) -> Self{
        var new = self
        new.context.transitionType = value
        return new
    }
    
    public func transitionDelegateSearchType(_ value: EZTransitionControllerDelegateSearchType) -> Self{
        var new = self
        new.context.transitionDelegateSearchType = value
        return new
    }
    
    public func presentationStyle(_ value: UIModalPresentationStyle) -> Self{
        var new = self
        new.context.presentationStyle = value
        return new
    }
    
    public func animation(_ value: UIModalTransitionStyle) -> Self{
        var new = animate()
        new.context.transitionStyle = value
        return new
    }
    
    public func animation(_ value: UIViewControllerAnimatedTransitioning) -> Self{
        var new = animate()
        new.context.animation = value
        return new
    }
    
    public func animate() -> Self{
        var new = self
        new.context.animate = true
        return new
    }
    
    public func completion(_ value: @escaping () -> Void) -> Self{
        var new = self
        new.context.completion = value
        return new
    }
}

protocol EZCustomTransitionProtocol: EZTransitionProtocol<EZCustomTransitionContext>{}

@available(iOS 13.0, *)
extension EZTransitionProtocol<EZCustomTransitionContext>{
    @MainActor
    @discardableResult
    public func asyncTransit() async -> Bool {
        await withCheckedContinuation { continuation in
            var continuation = Optional(continuation)
            let transition = completion {[completion = context.completion] in
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
public struct EZCustomTransition: EZTransitionProtocol{
    public var context: EZCustomTransitionContext
    
    public init(
        container: UIViewController,
        toController: UIViewController? = nil
    ) {
        self.context = .init(fromController: container, toController: toController)
    }
    
    public init(
        transitionController: EZTransitionControllerProtocol,
        toController: UIViewController? = nil
    ) {
        self.context = .init(transitionController: transitionController, toController: toController)
    }
    
    @_disfavoredOverload
    public init(
        container: UIViewController,
        toIndex: Int? = nil
    ) {
        self.context = .init(fromController: container, toIndex: toIndex)
    }
    
    @_disfavoredOverload
    public init(
        transitionController: EZTransitionControllerProtocol,
        toIndex: Int? = nil
    ) {
        self.context = .init(transitionController: transitionController, toIndex: toIndex)
    }
    
    @MainActor
    @discardableResult
    public func transit() -> Bool {
        if let transitionController = context.transitionController{
            return transitionController.transit(context: context)
        }else if let fromController = context.fromController{
            return context.transitionDelegateSearchType
                .search(to: fromController)?
                .transit(context: context) ?? false
        }else {
            return false
        }
    }
}
