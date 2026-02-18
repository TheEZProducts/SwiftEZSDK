# EZTransition — Точка входа

`EZTransition<Container>` — обёртка, предоставляющая fluent API для создания переходов. Доступ к ней осуществляется через свойство **`ezTransit`**.

---

## Использование

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

Объекты, реализующие `EZTransitionControllerProtocol`, получают свойство `transition`:

```swift
transitionController.transition.custom()                 // → EZCustomTransition
transitionController.transition.customTo(controller: vc)  // → EZCustomTransition
transitionController.transition.customTo(index: 2)        // → EZCustomTransition
```

---

## Связанные темы

- [Общие концепции переходов](../README.md) — fluent API, transit(), asyncTransit(), анимации.
- [EZBaseTransition](../EZBaseTransition/README.md) — модальные переходы (present/dismiss).
- [EZNavigationTransition](../EZNavigationTransition/README.md) — переходы в UINavigationController.
- [EZTabBarTransition](../EZTabBarTransition/README.md) — переходы для UITabBarController.
- [EZPageTransition](../EZPageTransition/README.md) — переходы для UIPageViewController.
- [EZCustomTransition](../EZCustomTransition/README.md) — кастомные переходы через EZTransitionController.
