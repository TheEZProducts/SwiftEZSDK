# EZTabBarTransition -- UITabBarController Transitions

`EZTabBarTransition` is a set of transitions for `UITabBarController`: setting tabs (set), selecting by controller or index (select), next/previous tab (next, back), and tab replacement (replace). The entry point is the **`ezTransit`** property on `UIViewController`. The recommended call site is the tab bar controller itself; if needed, you can call it on a child VC -- the tab bar will be resolved via `tabBarController`.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Basic Example](#basic-example)
3. [Available Transitions via ezTransit](#available-transitions-via-eztransit)
4. [Transition Parameters](#transition-parameters)
5. [Additional Scenarios](#additional-scenarios)
6. [Related Topics](#related-topics)

---

## Introduction

Seven types of transitions are available:

- **Setting tabs:** set (array or single controller).
- **Switching tabs:** select by controller, select by index, next, back.
- **Replacement:** replace -- if the controller is already in the tab bar, that tab is selected; otherwise, the currently selected tab is replaced.

All transitions support:

- custom animations via `UIViewControllerAnimatedTransitioning`;
- completion handler on transition finish;
- interactive transitions (swipe, etc.);
- asynchronous execution via `asyncTransit()` (async/await).

The container is **`UIViewController`** only. The recommended approach is to call the transition on the **`UITabBarController`** itself (`tabBarController.ezTransit....`). Additionally, calling it on a child controller is supported (e.g., the current screen in a tab) -- the tab bar is resolved automatically via `container.tabBarController`.

The context is **`EZChildTransitionContext`**: no modal presentation styles, only custom animation or `animate()`.

---

## Basic Example

In all examples below, **`ezTransit`** is called on the tab bar controller -- this is the primary and most convenient approach. If needed, the same call can be made on a child VC: the tab bar is resolved automatically.

**Setting tabs:**

```swift
tabBarController.ezTransit.tabBarSet([homeVC, profileVC, settingsVC])
    .animation(.ezShift(direction: .left))
    .transit()
```

**Selecting a tab by index:**

```swift
tabBarController.ezTransit.tabBarSelect(2)
    .animate()
    .completion { print("Tab selected") }
    .transit()
```

**Next / previous tab:**

```swift
tabBarController.ezTransit.tabBarNext()
    .animate()
    .transit()

// or
tabBarController.ezTransit.tabBarBack()
    .animate()
    .transit()
```

The method chain configures the transition; **`transit()`** executes it and returns `true` if the transition was started, or `false` if not (no tab bar, another transition already in progress, next/back at the boundary, etc.).

---

## Available Transitions via ezTransit

It is best to call the transition on the **`UITabBarController`** (`tabBarController.ezTransit....`). You can also call it on a child VC -- the tab bar will be found via `tabBarController`. Then chain methods from the [Transition Parameters](#transition-parameters) section, and finish with **`transit()`** or **`asyncTransit()`**.

### Setting Tabs

| Call | Description |
|------|-------------|
| `tabBarController.ezTransit.tabBarSet(_ controllers: [UIViewController])` | Replace all tabs with an array of controllers. |
| `tabBarController.ezTransit.tabBarSet(_ controller: UIViewController)` | Convenience variant: a single controller as the only tab. |

### Switching and Replacing Tabs

| Call | Description |
|------|-------------|
| `tabBarController.ezTransit.tabBarSelect(_ controller: UIViewController)` | Select a tab by controller. The controller must be in the tab bar's `viewControllers`. |
| `tabBarController.ezTransit.tabBarSelect(_ index: Int)` | Select a tab by index. |
| `tabBarController.ezTransit.tabBarNext()` | Select the next tab. On the last tab, `transit()` returns `false`. |
| `tabBarController.ezTransit.tabBarBack()` | Select the previous tab. On the first tab, `transit()` returns `false`. |
| `tabBarController.ezTransit.tabBarReplace(_ controller: UIViewController)` | If the controller is already in the tab bar -- selects that tab; otherwise replaces the **currently selected** tab with this controller. Called on a child VC (the container must have a `tabBarController`). |

---

## Transition Parameters

All methods return the same transition (or a new one with an updated context), so they can be chained together.

| Method | Effect on Transition |
|--------|----------------------|
| **`animation(_ value: UIViewControllerAnimatedTransitioning)`** | Custom animation (your own implementation or built-in `.ezShift(direction:)`, etc.). Enables animation (as if `animate()` was called). |
| **`animate()`** | Enable transition animation. Without it, the transition executes without animation. |
| **`completion(_ value: () -> Void)`** | Closure called upon transition completion. |
| **`safeTransition(_ value: Bool)`** | By default, the transition is safe: a repeated call during another transition is blocked. Explicit "unsafe" mode is `unsafeTransition()` or `safeTransition(false)`. |
| **`unsafeTransition()`** | Allow starting a transition while another is in progress. |
| **`interactive(_ value: (UIPercentDrivenInteractiveTransition) -> Void)`** | Interactive transition handler: the closure receives an object for controlling progress (swipe, etc.). |

The **`animation(...)`** method automatically enables animation -- there is no need to call `animate()` separately after it.

**Execution** -- see [transit() and asyncTransit()](../README.md#executing-transitions-transit-and-asynctransit).

---

## Additional Scenarios

Concepts common to all transitions (custom animations, async/await, duplicate call protection) are described in [General Transition Concepts](../README.md).

### When transit() Returns false

`transit()` returns `false` if:

- no `UITabBarController` is available (neither the container itself nor `container.tabBarController`);
- another transition is already in progress and `unsafeTransition()` was not used;
- **tabBarNext:** the last tab is already selected (`(selectedIndex + 1) >= viewControllers.count`);
- **tabBarBack:** the first tab is already selected (`selectedIndex - 1 < 0`);
- **tabBarSelect(controller):** the passed controller is not found in the tab bar's `viewControllers`;
- **tabBarReplace:** the container has no `tabBarController`; or the controller is not found in the tabs and the tabs array is empty or the selected tab index is invalid for replacement.

---

## Related Topics

- [General Transition Concepts](../README.md) -- fluent API, transit(), asyncTransit(), animations.
- [EZTransitionAnimations](../EZTransitionAnimations/README.md) -- built-in animations (ezOpen, ezClose, ezShift, etc.).
- [EZBaseTransition](../EZBaseTransition/README.md) -- base modal transitions (present/dismiss).
- [EZNavigationTransition](../EZNavigationTransition/README.md) -- UINavigationController transitions (push/pop, etc.).
- [EZCustomTransition](../EZCustomTransition/README.md) -- custom transitions via EZTransitionController.
