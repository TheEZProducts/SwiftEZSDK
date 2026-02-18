# EZUIPackKit

A module for building UI using the **IMV (Interactor-Mediator-View)** architecture. Provides a clear separation of logic, state, and presentation, along with a convenient screen transition system.

---

## Quick Start

1. [Quick Start](QuickStart/README.md) — Creating your first Pack from scratch

---

## Xcode Templates

1. [Template Installation and Usage](Templates/README.md) — How to install and use the Xcode File Template for IMV

---

## Core Components

| Component | Description |
|-----------|-------------|
| `EZUIPack` | Container that combines Interactor, Mediator, and View |
| `EZUIPackI` / `EZUIPackInteractor` | Base Interactor class (inherits from `UIViewController`) |
| `EZUIPackM` / `EZUIPackMediator` | Base Mediator class (stores state and connects I and V) |
| `EZUIPackV` / `EZUIPackView` | Base View class (UIKit) |
| `EZUIPackSV` / `EZUIPackSView` | Base View class (SwiftUI) |
| `EZUIPackPlatformsV` | Multi-platform View (iOS, iPadOS, macCatalyst, etc.) |

---

## Specialized Interactors

| Type | Description |
|------|-------------|
| `EZUINavigationPackI` | Interactor based on `UINavigationController` |
| `EZUITabBarPackI` | Interactor based on `UITabBarController` |
| `EZUIPagePackI` | Interactor based on `UIPageViewController` |

---

## Wrapper Packs

| Type | Description |
|------|-------------|
| `EZUINavigationWrapperPack` | Wrapper for `UINavigationController` without custom logic |
| `EZUITabBarWrapperPack` | Wrapper for `UITabBarController` without custom logic |

---

## Transitions

Detailed documentation — [Transition System (EZTransition)](Transitions/README.md).

| Class / Method | Description |
|----------------|-------------|
| `ezTransit` | Entry point for the transition system |
| `present` / `dismiss` | Modal transitions |
| `navigationPush` / `navigationPop` / `navigationSet` | Navigation stack transitions |
| `tabBarSelect` / `tabBarNext` / `tabBarBack` | Tab bar transitions |
| `pageSet` | UIPageViewController transitions |
| `replace` | Universal controller replacement |
| `custom` | Custom transitions via `EZTransitionController` |

---

## Transition Animations

Detailed documentation — [EZTransitionAnimations](Transitions/EZTransitionAnimations/README.md).

| Class | Description |
|-------|-------------|
| `EZOpenAnimation` | Slide-in animation with specified direction |
| `EZCloseAnimation` | Slide-out animation with specified direction |
| `EZShiftAnimation` | Shift (for tab bar transitions) |
| `EZAppearanceAnimation` | Fade-in |
| `EZDisappearanceAnimation` | Fade-out |

---

## Useful Links

- [Package.swift](../../../Package.swift) — module definition in SPM
- [Source Code](../../../Sources/EZUI/EZUIPack/EZUIPackKit/) — module implementation
