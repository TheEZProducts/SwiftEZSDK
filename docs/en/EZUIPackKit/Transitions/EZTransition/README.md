# EZTransition -- Entry Point

`EZTransition<Container>` is a wrapper that provides a fluent API for creating transitions. It is accessed through the **`ezTransit`** property.

---

## Usage

### UIViewController

```swift
viewController.ezTransit.present(otherVC)       // → EZPresentTransition
viewController.ezTransit.dismiss()               // → EZDismissTransition
viewController.ezTransit.navigationPush(vc)      // → EZNavigationPushTransition
viewController.ezTransit.navigationPop()         // → EZNavigationPopTransition
viewController.ezTransit.navigationPopTo(vc)     // → EZNavigationPopToTransition
viewController.ezTransit.navigationPopToRoot()   // → EZNavigationPopToRootTransition
viewController.ezTransit.navigationSet([...])    // → EZNavigationSetTransition
viewController.ezTransit.navigationReplace(vc)   // → EZNavigationReplaceTransition
viewController.ezTransit.navigationReplaceTop(vc)// → EZNavigationReplaceTopTransition
viewController.ezTransit.tabBarSet([...])        // → EZTabBarSetTransition
viewController.ezTransit.tabBarSelect(vc)        // → EZTabBarSelectControllerTransition
viewController.ezTransit.tabBarSelect(0)         // → EZTabBarSelectIndexTransition
viewController.ezTransit.tabBarNext()            // → EZTabBarNextTransition
viewController.ezTransit.tabBarBack()            // → EZTabBarBackTransition
viewController.ezTransit.tabBarReplace(vc)       // → EZTabBarReplaceTransition
viewController.ezTransit.pageSet([...])          // → EZPageSetTransition
viewController.ezTransit.replace(vc)             // → EZReplaceTransitionProtocol
viewController.ezTransit.custom()                // → EZCustomTransition
viewController.ezTransit.customTo(controller: vc)// → EZCustomTransition
viewController.ezTransit.customTo(index: 2)      // → EZCustomTransition
```

### EZContainerView

```swift
containerView.ezTransit.present(vc)  // → EZPresentTransition<EZContainerView>
```

### EZTransitionControllerProtocol

Objects implementing `EZTransitionControllerProtocol` get a `transition` property:

```swift
transitionController.transition.custom()                 // → EZCustomTransition
transitionController.transition.customTo(controller: vc)  // → EZCustomTransition
transitionController.transition.customTo(index: 2)        // → EZCustomTransition
```

---

## Related Topics

- [General Transition Concepts](../README.md) -- fluent API, transit(), asyncTransit(), animations.
- [EZBaseTransition](../EZBaseTransition/README.md) -- modal transitions (present/dismiss).
- [EZNavigationTransition](../EZNavigationTransition/README.md) -- UINavigationController transitions.
- [EZTabBarTransition](../EZTabBarTransition/README.md) -- UITabBarController transitions.
- [EZPageTransition](../EZPageTransition/README.md) -- UIPageViewController transitions.
- [EZCustomTransition](../EZCustomTransition/README.md) -- custom transitions via EZTransitionController.
