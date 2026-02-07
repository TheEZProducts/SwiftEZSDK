# EZBaseTransition -- Base Transitions

`EZBaseTransition` is a set of base transitions for modal presentation and dismissal of screens. It works both with full-screen presentation from `UIViewController` and with displaying a controller inside an `EZContainerView`.

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

Base transitions include two types:

- **EZPresentTransition** -- modal screen presentation (present).
- **EZDismissTransition** -- modal screen dismissal (dismiss).

Both support:

- presentation style (fullScreen, pageSheet, etc.);
- system or custom animations;
- completion handler on finish;
- interactive transitions (swipe, etc.);
- asynchronous execution via `asyncTransit()` (async/await).

The entry point is the **`ezTransit`** property on `UIViewController` and `EZContainerView`. From it, you call `present(...)` or `dismiss()`.

---

## Basic Example

**Presenting a screen from a ViewController:**

```swift
let detailVC = DetailViewController()
viewController.ezTransit.present(detailVC)
    .presentationStyle(.fullScreen)
    .animation(.coverVertical)
    .transit()
```

**Dismissing the current screen:**

```swift
presentedVC.ezTransit.dismiss()
    .animate()
    .completion { print("Screen dismissed") }
    .transit()
```

**Presenting in a container (EZContainerView):**

```swift
containerView.ezTransit.present(childVC)
    .animate()
    .transit()
```

The method chain configures the transition; **`transit()`** executes it and returns `true` if the transition was started, or `false` if not (e.g., another transition is already in progress).

---

## Available Transitions via ezTransit

### From UIViewController

| Call | Description |
|------|-------------|
| `viewController.ezTransit.present(otherVC)` | Modally present another ViewController on top of the current one. Style and animation are set via context methods. |
| `viewController.ezTransit.dismiss()` | Dismiss the currently presented modal screen. Called on the controller that needs to be dismissed. |

### From EZContainerView

| Call | Description |
|------|-------------|
| `containerView.ezTransit.present(vc)` | Display a ViewController inside the container. Presentation occurs within the container context (without full-screen styles like pageSheet). |

After creating the transition, call methods from the [Transition Parameters](#transition-parameters) section, and finally call **`transit()`** (or **`asyncTransit()`**).

---

## Transition Parameters

All methods return the same transition (or a new one with an updated context), so they can be chained together.

| Method | Effect on Transition |
|--------|----------------------|
| **`presentationStyle(_ value: UIModalPresentationStyle)`** | Modal presentation style: `.fullScreen`, `.pageSheet`, `.formSheet`, `.overFullScreen`, etc. Only for present from `UIViewController`. |
| **`animation(_ value: UIModalTransitionStyle)`** | System appearance/disappearance animation: `.coverVertical`, `.crossDissolve`, `.flipHorizontal`. Enables animation (as if `animate()` was called). |
| **`animation(_ value: UIViewControllerAnimatedTransitioning)`** | Custom animation (your own implementation or built-in `.ezOpen(direction:)` / `.ezClose(direction:)`). Also enables animation. |
| **`animate()`** | Enable transition animation. Without it, present/dismiss executes without animation. |
| **`completion(_ value: () -> Void)`** | Closure called upon transition completion (successful or cancelled). |
| **`unsafeTransition()`** | Allow starting a transition while another is in progress. By default, a repeated call in this situation is blocked and `transit()` returns `false`. |
| **`interactive(_ value: (UIPercentDrivenInteractiveTransition) -> Void)`** | Interactive transition handler: the closure receives an object that can be used to control progress (swipe back, etc.). |

**Execution** -- see [transit() and asyncTransit()](../README.md#executing-transitions-transit-and-asynctransit).

---

## Additional Scenarios

Concepts common to all transitions (custom animations, async/await, duplicate call protection) are described in [General Transition Concepts](../README.md).

### Present from Container (EZContainerView)

When presenting from `EZContainerView`, the presentation style is fixed (container context), but you can still use the same animation and completion methods. This is convenient for nested screens within a single container.

---

## Related Topics

- [General Transition Concepts](../README.md) -- fluent API, transit(), asyncTransit(), animations.
- [EZTransitionAnimations](../EZTransitionAnimations/README.md) -- built-in animations (ezOpen, ezClose, ezShift, etc.).
- [EZNavigationTransition](../EZNavigationTransition/README.md) -- UINavigationController transitions (push/pop, etc.).
- [EZTabBarTransition](../EZTabBarTransition/README.md) -- UITabBarController transitions.
- [EZCustomTransition](../EZCustomTransition/README.md) -- custom transitions via EZTransitionController.
