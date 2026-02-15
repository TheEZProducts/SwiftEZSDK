//
//  EZContainerView.swift
//  EZSDK
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

/// A dummy tab bar controller used internally by `EZContainerView` for presentation management.
///
/// This controller is used to handle modal presentations within a container view.
/// It's hidden and used only for UIKit's presentation system.
open class EZDummyTabBarController: UITabBarController {
    var viewDidAppearAction: (() -> ())?
    private var wasDisappeared: Bool = false
    
    open override func viewDidAppear(_ animated: Bool) {
        guard wasDisappeared else { return }
        viewDidAppearAction?()
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        wasDisappeared = true
    }
}

/// A container view that can present view controllers modally within itself.
///
/// `EZContainerView` allows you to present view controllers in a specific area of your view hierarchy,
/// rather than presenting them from the entire screen. It manages a dummy view controller internally
/// to handle UIKit's presentation system.
///
/// ### Example: Presenting a view controller in a container
///
/// ```swift
/// let containerView = EZContainerView()
/// containerView.frame = CGRect(x: 0, y: 0, width: 300, height: 400)
/// parentView.addSubview(containerView)
///
/// let presentedVC = MyViewController()
/// containerView.present(presentedVC, animated: true)
/// ```
///
/// - Note: The container view automatically manages the dummy controller lifecycle.
open class EZContainerView: UIView {
    /// The currently presented view controller, if any.
    ///
    /// Set automatically when a view controller is presented or dismissed.
    public weak var currentViewController: UIViewController?
    
    /// The dummy controller used internally for presentation management.
    ///
    /// Created automatically when needed and removed when no longer needed.
    public var dummyController: EZDummyTabBarController?
    
    /// A callback that's invoked when the presentation status changes.
    ///
    /// - Parameters:
    ///   - container: The container view whose status changed.
    ///   - isPresenting: `true` when starting to present, `false` when dismissing.
    public var presentationStatusDidUpdateAction: ((_ container: EZContainerView, _ isPresenting: Bool) -> ())?
    
    /// The parent view controller that contains this container view.
    ///
    /// Searches up the responder chain to find the nearest `UIViewController`.
    open var parentViewController: UIViewController? {
        var responder: UIResponder? = self
        while let next = responder?.next {
            if let viewController = next as? UIViewController {
                return viewController
            }
            responder = next
        }
        return nil
    }
    
    /// Provides access to transition operations for this container view.
    ///
    /// Use this to perform custom transitions and other view controller operations.
    open var ezTransit: EZTransition<EZContainerView> { .init(self) }
    
    /// Called when the container view is added to or removed from a superview.
    ///
    /// Automatically updates the dummy controller when the view hierarchy changes.
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateDummyController()
    }
    
    /// Presents a view controller modally within this container view.
    ///
    /// The view controller will be presented in the container's bounds, not full screen.
    ///
    /// - Parameters:
    ///   - viewControllerToPresent: The view controller to present.
    ///   - flag: Whether the presentation should be animated.
    ///   - completion: A closure to execute after the presentation completes.
    open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil){
        setDummyController()
        updateDummyController()
        viewControllerToPresent.modalPresentationStyle = .currentContext
        dummyController?.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    /// Creates and sets up the dummy controller if it doesn't exist.
    ///
    /// Called automatically when a view controller is presented. You typically don't need
    /// to call this manually.
    open func setDummyController() {
        guard dummyController == nil else { return }
        presentationStatusDidUpdateAction?(self, true)
        let dummy = EZDummyTabBarController()
        dummy.view.alpha = 0
        if #available(iOS 18.0, tvOS 18.0, visionOS 2.0, *) {
            dummy.mode = .tabBar
            dummy.setTabBarHidden(true, animated: false)
        } else {
            dummy.tabBar.isHidden = true
        }
        dummyController = dummy
    }
    
    /// Removes the dummy controller and cleans up presentation state.
    ///
    /// Called automatically when the presented view controller is dismissed. You typically
    /// don't need to call this manually.
    open func removeDummyController(){
        presentationStatusDidUpdateAction?(self, false)
        dummyController?.willMove(toParent: nil)
        dummyController?.view.removeFromSuperview()
        dummyController?.removeFromParent()
        dummyController = nil
        currentViewController = nil
    }
    
    /// Updates the dummy controller's parent relationship.
    ///
    /// Called automatically when the view hierarchy changes. You typically don't need
    /// to call this manually.
    open func updateDummyController(){
        guard
            let dummyController,
            let parentViewController,
            currentViewController != parentViewController
        else { return }
        dummyController.viewDidAppearAction = nil
        parentViewController.addChild(dummyController)
        if currentViewController == nil {
            dummyController.view.frame = bounds
            addSubview(dummyController.view)
        }
        dummyController.didMove(toParent: parentViewController)
        if #available(iOS 13.0, tvOS 13.0, *) {
            Task {
                dummyController.viewDidAppearAction = {[weak self] in
                    self?.removeDummyController()
                }
            }
        } else {
            DispatchQueue.main.async { [weak dummyController, weak self] in
                dummyController?.viewDidAppearAction = {
                    self?.removeDummyController()
                }
            }
        }
        currentViewController = parentViewController
    }
}
#endif
