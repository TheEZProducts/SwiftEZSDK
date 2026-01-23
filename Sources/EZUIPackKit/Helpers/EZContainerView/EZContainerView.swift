//
//  EZContainerView.swift
//  EZSDK
//
//  Created by Александр Сенин on 16.02.2025.
//

#if canImport(UIKit) && !os(watchOS)
import UIKit

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

open class EZContainerView: UIView {
    public weak var currentViewController: UIViewController?
    public var dummyController: EZDummyTabBarController?
    public var presentationStatusDidUpdateAction: ((_ container: EZContainerView, _ isPresenting: Bool) -> ())?
    
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
    
    open var transit: EZTransition<EZContainerView> { .init(self) }
    
    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        updateDummyController()
    }
    
    open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil){
        setDummyController()
        updateDummyController()
        viewControllerToPresent.modalPresentationStyle = .currentContext
        dummyController?.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
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
    
    open func removeDummyController(){
        presentationStatusDidUpdateAction?(self, false)
        dummyController?.willMove(toParent: nil)
        dummyController?.view.removeFromSuperview()
        dummyController?.removeFromParent()
        dummyController = nil
        currentViewController = nil
    }
    
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
        Task {
            dummyController.viewDidAppearAction = {[weak self] in
                self?.removeDummyController()
            }
        }
        currentViewController = parentViewController
    }
}
#endif
