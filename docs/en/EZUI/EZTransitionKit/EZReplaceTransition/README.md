# EZReplaceTransition -- Universal Controller Replacement

`EZReplaceTransition` is a universal transition that automatically determines the controller replacement method based on the type of the parent container.

---

## Usage

```swift
viewController.ezTransit.replace(newVC)
    .animate()
    .transit()
```

The **`replace`** method checks `controller.parent`:

- If the parent is a `UINavigationController` -- [`navigationReplace`](../EZNavigationTransition/README.md) is used.
- Otherwise -- [`tabBarReplace`](../EZTabBarTransition/README.md) is used.

The return type is `any EZReplaceTransitionProtocol<EZChildTransitionContext>`, so all [EZChildTransitionContext](../README.md#fluent-api) parameters are available: `animation()`, `animate()`, `completion()`, `safeTransition()`, `unsafeTransition()`, `interactive()`.

---

## When to Use

`replace` is convenient when you don't know in advance which container holds the controller. If the container is known, it is recommended to call the specific transition directly:

```swift
// Navigation
viewController.ezTransit.navigationReplace(newVC).animate().transit()

// TabBar
viewController.ezTransit.tabBarReplace(newVC).animate().transit()
```

---

## Related Topics

- [EZNavigationTransition](../EZNavigationTransition/README.md) -- `navigationReplace`, `navigationReplaceTop`.
- [EZTabBarTransition](../EZTabBarTransition/README.md) -- `tabBarReplace`.
- [General Transition Concepts](../README.md) -- fluent API, transit(), asyncTransit().
