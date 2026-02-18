# EZNavigationTransition -- UINavigationController Transitions

`EZNavigationTransition` is a set of transitions for `UINavigationController`: push, pop, popTo, popToRoot, set, replace, replaceTop. The entry point is the **`ezTransit`** property on `UIViewController`. It is best to call **`ezTransit`** on the navigation controller itself; if needed, you can also call it on a child VC -- the navigation controller will be found via the stack (`navigationController`).

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

- **Stack navigation:** push, pop, popTo, popToRoot.
- **Stack replacement:** set, replace, replaceTop.

All transitions support:

- custom animations via `UIViewControllerAnimatedTransitioning`;
- completion handler on transition finish;
- interactive transitions (swipe, etc.);
- asynchronous execution via `asyncTransit()` (async/await).

The container is **`UIViewController`** only. The recommended approach is to call the transition on the **`UINavigationController`** itself (`navigationController.ezTransit.navigationPush(...)`). Additionally, calling it on a child stack controller is supported -- the navigation controller is resolved automatically (`childVC.ezTransit.navigationPush(...)` finds the parent via `childVC.navigationController`).

The context is **`EZChildTransitionContext`**: no modal presentation styles, only custom animation or `animate()`.

---

## Basic Example

In all examples below, **`ezTransit`** is called on the navigation controller -- this is the primary and most convenient approach. If needed, the same call can be made on a child VC (e.g., the current screen): the navigation controller is resolved automatically.

**Pushing a screen:**

```swift
let detailVC = DetailViewController()
navigationController.ezTransit.navigationPush(detailVC)
    .animation(.ezOpen(direction: .right))
    .transit()
```

**Popping the current screen:**

```swift
navigationController.ezTransit.navigationPop()
    .animate()
    .completion { print("Screen dismissed") }
    .transit()
```

**Full stack replacement (popToRoot or set):**

```swift
navigationController.ezTransit.navigationPopToRoot()
    .animate()
    .transit()

// or set the stack explicitly:
navigationController.ezTransit.navigationSet([rootVC, vc1, vc2])
    .animate()
    .transit()
```

The method chain configures the transition; **`transit()`** executes it and returns `true` if the transition was started, or `false` if not (no UINavigationController, another transition already in progress, invalid stack, etc.).

---

## Available Transitions via ezTransit

It is best to call the transition on the **`UINavigationController`** (`navigationController.ezTransit....`). You can also call it on a child VC -- the navigation controller will be found via the stack. Then chain methods from the [Transition Parameters](#transition-parameters) section, and finish with **`transit()`** or **`asyncTransit()`**.

### Stack Navigation

| Call | Description |
|------|-------------|
| `navigationController.ezTransit.navigationPush(_ controller)` | Push a controller onto the top of the stack. The argument must not be a `UINavigationController`. |
| `navigationController.ezTransit.navigationPop()` | Remove the top controller from the stack. |
| `navigationController.ezTransit.navigationPopTo(_ controller)` | Pop to the specified controller (it must be in the stack). |
| `navigationController.ezTransit.navigationPopToRoot()` | Pop to the root controller of the stack. |

### Stack Replacement

| Call | Description |
|------|-------------|
| `navigationController.ezTransit.navigationSet(_ controllers: [UIViewController])` | Full stack replacement with an array of controllers. The array must not contain `UINavigationController`. |
| `replacedVC.ezTransit.navigationReplace(_ controller)` | Replace the **current** controller with another. Called on the **controller being replaced** (navigation is resolved via the stack); the passed controller takes its place. |
| `navigationController.ezTransit.navigationReplaceTop(_ controller)` | Replace only the **top** screen of the stack. |

---

## Transition Parameters

All methods return the same transition (or a new one with an updated context), so they can be chained together.

| Method | Effect on Transition |
|--------|----------------------|
| **`animation(_ value: UIViewControllerAnimatedTransitioning)`** | Custom animation (your own implementation or built-in `.ezOpen(direction:)` / `.ezClose(direction:)`). Enables animation (as if `animate()` was called). |
| **`animate()`** | Enable transition animation. Without it, the transition executes without animation. |
| **`completion(_ value: () -> Void)`** | Closure called upon transition completion (via `transitionCoordinator.animate(..., completion:)`). |
| **`safeTransition(_ value: Bool)`** | By default, the transition is safe (`safeTransition(true)`): a repeated call during another transition is blocked. Explicit "unsafe" mode is `unsafeTransition()` or `safeTransition(false)`. |
| **`unsafeTransition()`** | Allow starting a transition while another is in progress. |
| **`interactive(_ value: (UIPercentDrivenInteractiveTransition) -> Void)`** | Interactive transition handler: the closure receives an object for controlling progress (swipe back, etc.). |

The **`animation(...)`** and **`animate()`** methods work in concert: `animation(UIViewControllerAnimatedTransitioning)` automatically enables animation -- there is no need to call `animate()` separately after it.

**Execution** -- see [transit() and asyncTransit()](../README.md#executing-transitions-transit-and-asynctransit).

---

## Additional Scenarios

Concepts common to all transitions (custom animations, async/await, duplicate call protection) are described in [General Transition Concepts](../README.md).

### When transit() Returns false

`transit()` returns `false` if:

- no `UINavigationController` is available;
- another transition is already in progress and `unsafeTransition()` was not used;
- for push/set/replace: a `UINavigationController` is passed in the stack or as an argument (pushing a NC is not allowed);
- for popTo: the target controller is not found in the stack;
- for replace: the current controller is not in the navigation stack (replace is called on the VC being replaced);
- for replaceTop: there is no `topViewController`, etc.

---

## Related Topics

- [General Transition Concepts](../README.md) -- fluent API, transit(), asyncTransit(), animations.
- [EZTransitionAnimations](../EZTransitionAnimations/README.md) -- built-in animations (ezOpen, ezClose, ezShift, etc.).
- [EZBaseTransition](../EZBaseTransition/README.md) -- base modal transitions (present/dismiss).
- [EZTabBarTransition](../EZTabBarTransition/README.md) -- UITabBarController transitions.
- [EZCustomTransition](../EZCustomTransition/README.md) -- custom transitions via EZTransitionController.
