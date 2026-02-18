# EZCustomTransition -- Custom Transitions

`EZCustomTransition` provides a mechanism for delegating transitions to parent controllers in the ViewController hierarchy. Child screens can send events about their state and pass parameters, while parent controllers handle these events and perform the appropriate transitions.

---

## Table of Contents

1. [Introduction](#introduction)
2. [Quick Start](#quick-start)
3. [Core Components](#core-components)
4. [Configuration Methods](#configuration-methods)
5. [Examples](#examples)

---

## Introduction

Custom transitions (`EZCustomTransition`) allow child screens to delegate transition management to their parent controllers. This is especially useful for:

- **Modal dialogs** -- a child screen can notify the parent about the need to close or navigate to the next screen
- **Navigation stacks** -- a child screen can request navigation to the next screen or going back
- **Onboarding** -- each onboarding screen can send events (`ezNext`, `ezBack`), and the parent navigation controller handles them and manages the flow

**How it works:**

1. **Child screen** sends an event via `ezTransit.custom()` with a specified transition type (`.ezNext`, `.ezBack`, etc.)
2. **The system searches** for a `transitionController` in the ViewController hierarchy according to `transitionDelegateSearchType`
3. **Parent controller** receives the event through its `EZTransitionControllerDelegateProtocol` implementation and performs the appropriate transition

---

## Quick Start

Let's look at a complete onboarding usage example:

```swift
// Parent controller implements the transition handling protocol
class OnboardingNavigationController: UINavigationController, EZTransitionControllerDelegateProtocol {
    private let onboardingSteps: [UIViewController.Type] = [
        OnboardingStep1ViewController.self,
        OnboardingStep2ViewController.self,
        OnboardingStep3ViewController.self
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create and configure the first onboarding screen with transition controller
        let step1 = OnboardingStep1ViewController()
            .apply(template: .custom {
                $0.transitionController = .delegate(self)
            })

        self.setViewControllers([step1], animated: false)
    }

    // Implement transition handling
    func transit(context: EZCustomTransitionContext) -> Bool {
        switch context.transitionType {
        case .ezNext:
            return handleNext(context: context)
        case .ezBack:
            return handleBack(context: context)
        default:
            return false
        }
    }

    private func handleNext(context: EZCustomTransitionContext) -> Bool {
        // Determine current screen index by stack count
        let currentIndex = self.viewControllers.count - 1

        // Check if there is a next screen
        if currentIndex + 1 < onboardingSteps.count {
            // Navigate to the next screen
            let nextVCType = onboardingSteps[currentIndex + 1]
            let nextVC = nextVCType.init()
                .apply(template: .custom {
                    $0.transitionController = .delegate(self)
                })
            self.pushViewController(nextVC, animated: context.animate)
            return true
        } else {
            // If this was the last screen — close onboarding
            self.dismiss(animated: context.animate)
            return true
        }
    }

    private func handleBack(context: EZCustomTransitionContext) -> Bool {
        if self.viewControllers.count > 1 {
            self.popViewController(animated: context.animate)
            return true
        }
        return false
    }
}

// Child screens simply send events
class OnboardingStep1ViewController: UIViewController {
    func nextButtonTapped() {
        // Send event to parent (navigation controller)
        self.ezTransit.custom()
            .transitionType(.ezNext)
            .transit()
    }
}

class OnboardingStep2ViewController: UIViewController {
    func nextButtonTapped() {
        self.ezTransit.custom()
            .transitionType(.ezNext)
            .transit()
    }

    func backButtonTapped() {
        self.ezTransit.custom()
            .transitionType(.ezBack)
            .transit()
    }
}

class OnboardingStep3ViewController: UIViewController {
    func finishButtonTapped() {
        // Send .ezNext — parent will determine it's the last screen and close onboarding
        self.ezTransit.custom()
            .transitionType(.ezNext)
            .transit()
    }

    func backButtonTapped() {
        self.ezTransit.custom()
            .transitionType(.ezBack)
            .transit()
    }
}
```

**Key points:**

1. **Parent controller** (`OnboardingNavigationController`) implements `EZTransitionControllerDelegateProtocol` directly
2. **Transition controller is set on child screens** via `.apply(template: .custom { $0.transitionController = .delegate(self) })`
3. **Close handling** is combined with `.ezNext` handling -- if it's the last screen, the parent closes the onboarding itself
4. **Child screens** simply send events via `ezTransit.custom()` with parent lookup specified

---

## Core Components

### EZTransitionControllerProtocol

A protocol for objects that can handle custom transitions. Primary method:

```swift
@MainActor
public protocol EZTransitionControllerProtocol: AnyObject {
    @discardableResult
    func transit(context: EZCustomTransitionContext) -> Bool
}
```

The `transit(context:)` method analyzes `context.transitionType` and executes the corresponding logic. Returns `true` if the transition was handled, `false` otherwise.

### EZTransitionController

Base implementation of `EZTransitionControllerProtocol`. Can be created using a closure or delegate:

```swift
// With closure
let controller = EZTransitionController { context in
    // Transition handling
    return true
}

// With delegate
let controller = EZTransitionController(delegate: myDelegate)
```

For convenient installation on a child screen, use:

```swift
childVC.apply(template: .custom {
    $0.transitionController = .delegate(self)
})
```

### EZCustomTransitionContext

The transition context contains all the information needed for handling:

- `transitionType` -- the transition type (`.ezNext`, `.ezBack`, `.ezClose`, etc.)
- `customData` -- arbitrary data for passing
- `fromController` -- the controller where the transition originates
- `toController` -- the target controller (if specified)
- `toIndex` -- the target index (for index-based transitions)
- `animate` -- whether to animate the transition
- `animation` -- custom animation
- `completion` -- completion handler

### EZCustomTransitionType

The transition type is identified by a string key. Predefined types:

- `.ezNext` -- navigate to the next element
- `.ezBack` -- return to the previous element
- `.ezToController` -- navigate to a specific controller
- `.ezToIndex` -- navigate to a specific index
- `.ezOpen` -- open/present
- `.ezClose` -- close/dismiss
- `.ezSuccess` -- successful operation completion
- `.ezFail` -- failed operation completion

You can also create a custom type via extension:

```swift
extension EZCustomTransitionType {
    static var myCustomType: Self {
        .init(key: "myCustomType")
    }

    static func myCustomType(customData: Any) -> Self {
        .init(key: "myCustomType", customData: customData)
    }
}

// Usage
viewController.ezTransit.custom()
    .transitionType(.myCustomType)
    .transit()
```

### Transition Controller Lookup

The system searches for a `transitionController` in the ViewController hierarchy according to `transitionDelegateSearchType`:

- **`.selfDelegate`** -- search only in the controller itself
- **`.parent`** -- search in the parent controller
- **`.hierarchy`** (default) -- search the entire hierarchy (self, parent, presenting, etc.)

---

## Configuration Methods

All configuration methods return a new transition instance with updated parameters (fluent interface).

| Method | Description |
|--------|-------------|
| `transitionType(_:)` | Sets the custom transition type (`.ezNext`, `.ezBack`, etc.) |
| `customData(_:)` | Sets arbitrary data for passing |
| `transitionDelegateSearchType(_:)` | Sets the transition controller lookup strategy (`.parent`, `.hierarchy`, `.selfDelegate`) |
| `animation(_ value: UIViewControllerAnimatedTransitioning)` | Sets a custom animation and automatically enables animation |
| `animation(_ value: UIModalTransitionStyle)` | Sets a system animation (`.coverVertical`, `.crossDissolve`, etc.) and automatically enables animation |
| `animate()` | Enables animation for the transition |
| `presentationStyle(_:)` | Sets the modal presentation style |
| `completion(_:)` | Sets the transition completion handler |
| `safeTransition(_ value: Bool)` | `true` -- block the transition during another transition (default). `false` -- allow |
| `unsafeTransition()` | Allow starting a transition while another is in progress |

**Important:** The `.animation()` methods automatically enable animation, so there is no need to call `.animate()` after them.

**Execution** -- see [transit() and asyncTransit()](../README.md#executing-transitions-transit-and-asynctransit).

---

## Examples

### Modal Dialog Example

A modal dialog requests closure from its parent:

```swift
// Parent controller
class ParentViewController: UIViewController, EZTransitionControllerDelegateProtocol {
    func showModal() {
        let modal = ModalViewController()
            .apply(template: .custom {
                $0.transitionController = .delegate(self)
            })
        self.present(modal, animated: true)
    }

    func transit(context: EZCustomTransitionContext) -> Bool {
        switch context.transitionType {
        case .ezClose:
            // Dismiss the modal (child)
            context.fromController?.dismiss(animated: context.animate)
            return true
        case .ezSuccess:
            // Handle successful save
            if let data = context.customData as? [String: Any] {
                // Use the data
            }
            // Dismiss the modal (child)
            context.fromController?.dismiss(animated: context.animate)
            return true
        default:
            return false
        }
    }
}

// Modal window
class ModalViewController: UIViewController {
    func closeButtonTapped() {
        self.ezTransit.custom()
            .transitionType(.ezClose)
            .transit()
    }

    func saveButtonTapped() {
        self.ezTransit.custom()
            .transitionType(.ezSuccess)
            .customData(["saved": true])
            .transit()
    }
}
```

---

## Related Topics

- [General Transition Concepts](../README.md) -- fluent API, transit(), asyncTransit(), animations.
- [EZBaseTransition](../EZBaseTransition/README.md) -- base modal transitions (present/dismiss).
- [EZNavigationTransition](../EZNavigationTransition/README.md) -- UINavigationController transitions.
- [EZTabBarTransition](../EZTabBarTransition/README.md) -- UITabBarController transitions.
