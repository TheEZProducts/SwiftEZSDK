//
//  UIViewControllerSettingsTemplate.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

import UIKit

@MainActor
public struct EZUIViewControllerSettingsTemplate<Controller: UIViewController>{
    private var template: (Controller)->()
    
    public func apply(to controller: Controller){
        template(controller)
    }
   
    public init(_ template: @escaping (Controller)->()) { self.template = template }
    
    public static func custom(_ template: @escaping (Controller)->()) -> Self { .init(template) }
}

public protocol EZTemplatebleViewControllerProtocol: UIViewController{}
extension EZTemplatebleViewControllerProtocol{
    @discardableResult
    public func apply(template: EZUIViewControllerSettingsTemplate<Self>) -> Self{
        template.apply(to: self)
        return self
    }
}
extension UIViewController: EZTemplatebleViewControllerProtocol{}



//MARK: - Templates
extension EZUIViewControllerSettingsTemplate{
    public static func group(
        _ templates: [Self]
    ) -> Self {
        .custom{ controller in
            templates.forEach{ $0.apply(to: controller) }
        }
    }
}

extension EZUIViewControllerSettingsTemplate where Controller: UINavigationController{
    public static var hiddenNavigationBar: Self {
        .custom{
            $0.navigationBar.isHidden = true
        }
    }
}

extension EZUIViewControllerSettingsTemplate where Controller: EZUINavigationPackProtocol{
    public static func childAnimations(
        push: UIViewControllerAnimatedTransitioning? = nil,
        pop: UIViewControllerAnimatedTransitioning? = nil
    ) -> Self {
        .custom{
            $0.defaultChildrenPushTransitionAnimation = push
            $0.defaultChildrenPopTransitionAnimation = pop
        }
    }
}

extension EZUIViewControllerSettingsTemplate where Controller: EZUITabBarPackProtocol{
    public static func childAnimation(
        animation: UIViewControllerAnimatedTransitioning? = nil
    ) -> Self {
        .custom{
            $0.defaultChildrenTransitionAnimation = animation
        }
    }
}
