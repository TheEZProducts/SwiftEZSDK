# EZPageTransition -- UIPageViewController Transitions

`EZPageTransition` is a transition for `UIPageViewController`: setting the displayed controllers with a specified navigation direction. The entry point is the **`ezTransit`** property on `UIViewController`.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Basic Example](#basic-example)
3. [Available Transitions via ezTransit](#available-transitions-via-eztransit)
4. [Transition Parameters](#transition-parameters)
5. [When transit() Returns false](#when-transit-returns-false)
6. [Related Topics](#related-topics)

---

## Introduction

The UIPageViewController transition sets a collection of controllers with a specified direction (`.forward` / `.reverse`).

The transition supports:

- navigation direction;
- animation;
- completion handler on finish;
- asynchronous execution via `asyncTransit()` (async/await).

The container is **`UIViewController`**. The recommended approach is to call the transition on the `UIPageViewController` itself. Additionally, calling it on a child controller is supported -- the page controller is resolved automatically.

The context is **`EZPageTransitionContext`**: direction, animation, and completion; no modal presentation styles or interactive transitions.

---

## Basic Example

```swift
pageController.ezTransit.pageSet([page1, page2, page3])
    .direction(.forward)
    .animate()
    .transit()
```

The method chain configures the transition; **`transit()`** executes it and returns `true` if the transition was started, or `false` if not.

---

## Available Transitions via ezTransit

| Call | Description |
|------|-------------|
| `pageController.ezTransit.pageSet(_ controllers: [UIViewController])` | Set the displayed controllers. |

Then chain methods from the [Transition Parameters](#transition-parameters) section, and finish with **`transit()`** or **`asyncTransit()`**.

---

## Transition Parameters

All methods return a transition with an updated context, so they can be chained together.

| Method | Effect on Transition |
|--------|----------------------|
| **`direction(_ value: UIPageViewController.NavigationDirection)`** | Navigation direction: `.forward` (default) or `.reverse`. |
| **`animate()`** | Enable transition animation. Without it, the transition executes without animation. |
| **`completion(_ value: () -> Void)`** | Closure called upon transition completion. |
| **`safeTransition(_ value: Bool)`** | By default, the transition is safe: a repeated call during another transition is blocked. `safeTransition(false)` is equivalent to `unsafeTransition()`. |
| **`unsafeTransition()`** | Allow starting a transition while another is in progress. |

**Execution** -- see [transit() and asyncTransit()](../README.md#executing-transitions-transit-and-asynctransit).

---

## When transit() Returns false

`transit()` returns `false` if:

- no `UIPageViewController` is available (neither the container itself nor via `pageController`).

---

## Related Topics

- [General Transition Concepts](../README.md) -- fluent API, transit(), asyncTransit(), animations.
- [EZNavigationTransition](../EZNavigationTransition/README.md) -- UINavigationController transitions.
- [EZTabBarTransition](../EZTabBarTransition/README.md) -- UITabBarController transitions.
