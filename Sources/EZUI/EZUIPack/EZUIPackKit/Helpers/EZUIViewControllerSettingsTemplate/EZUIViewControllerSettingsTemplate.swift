//
//  UIViewControllerSettingsTemplate.swift
//  EZSDK
//
//  Created by Александр Сенин on 17.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A template for applying settings to view controllers in a reusable way.
///
/// `EZUIViewControllerSettingsTemplate` allows you to define view controller configurations
/// that can be applied to multiple instances. This is useful for standardizing view controller
/// setup across your app.
///
/// ### Example: Creating and using a template
///
/// ```swift
/// // Create a template
/// let hiddenNavBarTemplate = EZUIViewControllerSettingsTemplate<UINavigationController>.hiddenNavigationBar
///
/// // Apply to a navigation controller
/// let navController = UINavigationController()
/// navController.apply(template: hiddenNavBarTemplate)
///
/// // Or use custom template
/// let customTemplate = EZUIViewControllerSettingsTemplate<MyViewController>.custom { vc in
///     vc.view.backgroundColor = .systemBackground
///     vc.title = "Custom"
/// }
/// myVC.apply(template: customTemplate)
/// ```
///
/// ### Example: Grouping templates
///
/// ```swift
/// let templates = [
///     EZUIViewControllerSettingsTemplate.hiddenNavigationBar,
///     EZUIViewControllerSettingsTemplate.childAnimations(push: customPushAnimation)
/// ]
/// let grouped = EZUIViewControllerSettingsTemplate.group(templates)
/// navController.apply(template: grouped)
/// ```
@MainActor
public struct EZUIViewControllerSettingsTemplate<Controller: UIViewController>{
    private var template: (Controller)->()
    
    /// Applies this template's settings to the given controller.
    ///
    /// - Parameter controller: The controller to configure.
    public func apply(to controller: Controller){
        template(controller)
    }
   
    /// Creates a template with a custom configuration closure.
    ///
    /// - Parameter template: A closure that configures the controller.
    public init(_ template: @escaping (Controller)->()) { self.template = template }
    
    /// Creates a template with a custom configuration closure.
    ///
    /// - Parameter template: A closure that configures the controller.
    /// - Returns: A new template instance.
    public static func custom(_ template: @escaping (Controller)->()) -> Self { .init(template) }
}

/// Protocol for view controllers that can have templates applied to them.
///
/// All `UIViewController` instances conform to this protocol by default.
public protocol EZTemplatebleViewControllerProtocol: UIViewController{}

extension EZTemplatebleViewControllerProtocol{
    /// Applies a template to this view controller and returns it for chaining.
    ///
    /// - Parameter template: The template to apply.
    /// - Returns: The view controller instance (for method chaining).
    ///
    /// ### Example
    /// ```swift
    /// let vc = MyViewController()
    ///     .apply(template: hiddenNavBarTemplate)
    ///     .apply(template: customTemplate)
    /// ```
    @discardableResult
    public func apply(template: EZUIViewControllerSettingsTemplate<Self>) -> Self{
        template.apply(to: self)
        return self
    }
}
extension UIViewController: EZTemplatebleViewControllerProtocol{}



//MARK: - Templates
extension EZUIViewControllerSettingsTemplate {
    /// Groups multiple templates into a single template that applies all of them.
    ///
    /// - Parameter templates: An array of templates to group together.
    /// - Returns: A new template that applies all the provided templates in order.
    ///
    /// ### Example
    /// ```swift
    /// let templates = [
    ///     .hiddenNavigationBar,
    ///     .childAnimations(push: customAnimation)
    /// ]
    /// let grouped = EZUIViewControllerSettingsTemplate.group(templates)
    /// navController.apply(template: grouped)
    /// ```
    public static func group(
        _ templates: [Self]
    ) -> Self {
        .custom{ controller in
            templates.forEach{ $0.apply(to: controller) }
        }
    }
}

extension EZUIViewControllerSettingsTemplate where Controller: UINavigationController {
    /// A template that hides the navigation bar.
    ///
    /// ### Example
    /// ```swift
    /// navController.apply(template: .hiddenNavigationBar)
    /// ```
    public static var hiddenNavigationBar: Self {
        .custom {
            $0.navigationBar.isHidden = true
        }
    }
}

extension EZUIViewControllerSettingsTemplate where Controller: EZUINavigationInteractorProtocol {
    /// A template that sets custom transition animations for child view controllers.
    ///
    /// - Parameters:
    ///   - push: The animation to use when pushing view controllers. If `nil`, uses default.
    ///   - pop: The animation to use when popping view controllers. If `nil`, uses default.
    /// - Returns: A template that configures the animations.
    ///
    /// ### Example
    /// ```swift
    /// let template = EZUIViewControllerSettingsTemplate.childAnimations(
    ///     push: .ezOpen(direction: .right),
    ///     pop: .ezClose(direction: .right)
    /// )
    /// navController.apply(template: template)
    /// ```
    public static func childAnimations(
        push: UIViewControllerAnimatedTransitioning? = nil,
        pop: UIViewControllerAnimatedTransitioning? = nil
    ) -> Self {
        .custom {
            $0.defaultChildrenPushTransitionAnimation = push
            $0.defaultChildrenPopTransitionAnimation = pop
        }
    }
}

extension EZUIViewControllerSettingsTemplate where Controller: EZUITabBarInteractorProtocol {
    /// A template that sets a custom transition animation for tab switching.
    ///
    /// - Parameter animation: The animation to use when switching tabs. If `nil`, uses default.
    /// - Returns: A template that configures the animation.
    ///
    /// ### Example
    /// ```swift
    /// let template = EZUIViewControllerSettingsTemplate.childAnimation(
    ///     animation: EZShiftAnimation.ezShift(direction: .left)
    /// )
    /// tabBarController.apply(template: template)
    /// ```
    public static func childAnimation(
        animation: UIViewControllerAnimatedTransitioning? = nil
    ) -> Self {
        .custom {
            $0.defaultChildrenTransitionAnimation = animation
        }
    }
}
#endif
