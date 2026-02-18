# EZTransitionAnimations -- Built-in Transition Animations

EZUIPackKit includes a set of built-in animations implementing `UIViewControllerAnimatedTransitioning`. All of them are available through factory methods with the `ez` prefix.

---

## Table of Contents

1. [EZAnimationDirection](#ezanimationdirection)
2. [EZOpenAnimation](#ezopenanimation)
3. [EZCloseAnimation](#ezcloseanimation)
4. [EZShiftAnimation](#ezshiftanimation)
5. [EZAppearanceAnimation](#ezappearanceanimation)
6. [EZDisappearanceAnimation](#ezdisappearanceanimation)
7. [Related Topics](#related-topics)

---

## EZAnimationDirection

An enumeration of directions for animations:

| Value | Description |
|-------|-------------|
| `.up` | From the top |
| `.down` | From the bottom |
| `.right` | From the right |
| `.left` | From the left |

---

## EZOpenAnimation

Slide-in animation: the new screen slides in from the specified direction, while the current screen shifts slightly (30%) in the opposite direction.

| Property | Default Value |
|----------|---------------|
| `direction` | `.up` |
| `duration` | `0.5` sec |

**Factories:**

```swift
.ezOpen                                    // direction: .up, duration: 0.5
.ezOpen(direction: .right)                 // direction: .right, duration: 0.5
.ezOpen(direction: .left, duration: 0.3)   // direction: .left, duration: 0.3
```

**Example:**

```swift
viewController.ezTransit.present(detailVC)
    .presentationStyle(.fullScreen)
    .animation(.ezOpen(direction: .up))
    .transit()
```

---

## EZCloseAnimation

Slide-out animation: the current screen slides out in the specified direction, while the underlying screen returns to its position (from a 30% offset).

| Property | Default Value |
|----------|---------------|
| `direction` | `.up` |
| `duration` | `0.5` sec |

**Factories:**

```swift
.ezClose                                    // direction: .up, duration: 0.5
.ezClose(direction: .down)                   // direction: .down, duration: 0.5
.ezClose(direction: .left, duration: 0.3)    // direction: .left, duration: 0.3
```

**Example:**

```swift
presentedVC.ezTransit.dismiss()
    .animation(.ezClose(direction: .down))
    .transit()
```

> **Tip:** Typically, `EZOpenAnimation` and `EZCloseAnimation` are used as a pair: open for present, close for dismiss (with the same direction).

---

## EZShiftAnimation

Parallel shift: the new screen slides in from the specified direction, while the old screen slides out in the opposite direction (full 100% offset). Suitable for tab switching and navigation.

| Property | Default Value |
|----------|---------------|
| `direction` | `.left` |
| `duration` | `0.5` sec |

**Factory:**

```swift
.ezShift(direction: .left)                  // direction: .left, duration: 0.5
.ezShift(direction: .right, duration: 0.3)  // direction: .right, duration: 0.3
```

**Example:**

```swift
tabBarController.ezTransit.tabBarNext()
    .animation(.ezShift(direction: .left))
    .transit()
```

---

## EZAppearanceAnimation

Fade-in animation: the new screen appears with alpha 0 -> 1.

| Property | Default Value |
|----------|---------------|
| `duration` | `0.2` sec |

**Factories:**

```swift
.ezAppearance                    // duration: 0.2
.ezAppearance(duration: 0.5)     // duration: 0.5
```

**Example:**

```swift
viewController.ezTransit.present(detailVC)
    .presentationStyle(.overFullScreen)
    .animation(.ezAppearance)
    .transit()
```

---

## EZDisappearanceAnimation

Fade-out animation: the current screen disappears with alpha 1 -> 0.

| Property | Default Value |
|----------|---------------|
| `duration` | `0.2` sec |

**Factories:**

```swift
.ezDisappearance                    // duration: 0.2
.ezDisappearance(duration: 0.5)     // duration: 0.5
```

**Example:**

```swift
presentedVC.ezTransit.dismiss()
    .animation(.ezDisappearance)
    .transit()
```

> **Tip:** `EZAppearanceAnimation` and `EZDisappearanceAnimation` are used as a pair: appearance for present, disappearance for dismiss.

---

## Related Topics

- [General Transition Concepts](../README.md) -- fluent API, transit(), asyncTransit(), creating your own animations.
- [EZBaseTransition](../EZBaseTransition/README.md) -- modal transitions (present/dismiss).
- [EZNavigationTransition](../EZNavigationTransition/README.md) -- UINavigationController transitions.
- [EZTabBarTransition](../EZTabBarTransition/README.md) -- UITabBarController transitions.
