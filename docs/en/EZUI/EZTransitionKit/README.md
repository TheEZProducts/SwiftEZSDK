# EZTransition -- Transition System

The `EZTransitionKit` module provides a unified transition system for managing navigation between screens. The entry point is the **`ezTransit`** property on `UIViewController` or `EZContainerView`.

---

## Sections

| Section | Description |
|---------|-------------|
| [EZTransition](EZTransition/README.md) | Entry point: `ezTransit` and `EZTransition<Container>` |
| [EZBaseTransition](EZBaseTransition/README.md) | Modal transitions: present / dismiss |
| [EZNavigationTransition](EZNavigationTransition/README.md) | UINavigationController transitions |
| [EZTabBarTransition](EZTabBarTransition/README.md) | UITabBarController transitions |
| [EZPageTransition](EZPageTransition/README.md) | UIPageViewController transitions |
| [EZReplaceTransition](EZReplaceTransition/README.md) | Universal controller replacement |
| [EZCustomTransition](EZCustomTransition/README.md) | Custom transitions via EZTransitionController |
| [EZTransitionAnimations](EZTransitionAnimations/README.md) | Built-in transition animations |

---

## General Concepts

1. [Fluent API](#fluent-api)
2. [Executing Transitions: transit() and asyncTransit()](#executing-transitions-transit-and-asynctransit)
3. [Duplicate Call Protection](#duplicate-call-protection)
4. [Custom Animations](#custom-animations)
5. [Built-in Animations](#built-in-animations)

---

## Fluent API

All transitions are configured using a method chain. Each method returns a transition with an updated context:

```swift
viewController.ezTransit.navigationPush(detailVC)
    .animation(.ezOpen(direction: .right))
    .completion { print("Done") }
    .transit()
```

---

## Executing Transitions: transit() and asyncTransit()

Every transition is finalized by calling one of two methods:

- **`transit() -> Bool`** -- execute the transition synchronously; returns `true` if the transition was started, and `false` otherwise (no container, another transition already in progress, invalid parameters, etc.).
- **`asyncTransit() async -> Bool`** (iOS 13+) -- execute the transition and await its completion via `completion`; returns `true` if the transition was successfully initiated.

```swift
let success = await viewController.ezTransit.present(detailVC)
    .animation(.coverVertical)
    .asyncTransit()

if success {
    print("Screen presented")
}
```

If the transition cannot be started, `asyncTransit()` returns `false` immediately.

---

## Duplicate Call Protection

By default, calling `transit()` again while another transition is already in progress does nothing and returns `false`. For special cases, you can call **`unsafeTransition()`** (or **`safeTransition(false)`**, where available) -- this skips the check:

```swift
viewController.ezTransit.navigationPush(detailVC)
    .unsafeTransition()
    .animate()
    .transit()
```

---

## Custom Animations

Instead of system styles, you can provide your own animation -- a class implementing `UIViewControllerAnimatedTransitioning`. Minimal example:

```swift
final class FadeAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval {
        0.3
    }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let toView = ctx.view(forKey: .to) else {
            ctx.completeTransition(false)
            return
        }
        toView.alpha = 0
        ctx.containerView.addSubview(toView)
        UIView.animate(withDuration: 0.3, animations: {
            toView.alpha = 1
        }) { _ in
            ctx.completeTransition(!ctx.transitionWasCancelled)
        }
    }
}

// Usage:
viewController.ezTransit.present(detailVC)
    .presentationStyle(.fullScreen)
    .animation(FadeAnimation())
    .transit()
```

Custom animations are passed via the **`.animation(UIViewControllerAnimatedTransitioning)`** method, which automatically enables animation (there is no need to call `.animate()` separately).

---

## Built-in Animations

EZTransitionKit includes built-in animations with the `ez` prefix. For details, see [EZTransitionAnimations](EZTransitionAnimations/README.md).

| Factory | Description |
|---------|-------------|
| `.ezOpen(direction:duration:)` | Slide-in: the new screen slides in from the specified direction, while the current screen shifts slightly (30%) in the opposite direction. |
| `.ezClose(direction:duration:)` | Slide-out: the current screen slides out in the specified direction, while the underlying screen returns to its position. |
| `.ezShift(direction:duration:)` | Parallel shift: the new screen slides in while the old screen slides out in the opposite direction (for tabs and navigation). |
| `.ezAppearance` / `.ezAppearance(duration:)` | Fade-in (alpha 0 -> 1). |
| `.ezDisappearance` / `.ezDisappearance(duration:)` | Fade-out (alpha 1 -> 0). |

```swift
// Usage examples:
.animation(.ezOpen(direction: .up))
.animation(.ezClose(direction: .down))
.animation(.ezShift(direction: .left))
.animation(.ezAppearance)
```
