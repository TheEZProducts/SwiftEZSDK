# EZSUIPackKit Quick Start

This guide shows how to create your first SwiftUI screen using the **IMV (Interactor-Mediator-View)** architecture.

---

## Table of Contents

- [IMV Architecture](#imv-architecture)
- [Creating a Pack](#creating-a-pack)
  - [1. Mediator](#1-mediator)
  - [2. Interactor](#2-interactor)
  - [3. View](#3-view)
  - [4. Assembling the Pack](#4-assembling-the-pack)
- [Passing External Data](#passing-external-data)
- [Reactivity](#reactivity)
- [InputV for SwiftUI Views](#inputv-for-swiftui-views)
- [Common Mistakes](#common-mistakes)

---

## IMV Architecture

A **Pack** is a screen or application module consisting of three components:

| Component | Responsibility |
|-----------|----------------|
| **Interactor** | Business logic, data loading, lifecycle. Plain class (not a `UIViewController`). |
| **Mediator** | Stores the `ViewModel` (UI state), provides `inputI` and `inputV` interfaces for interaction. |
| **View** | UI rendering using native SwiftUI. |

### How Components Interact

**Important:** Interactor and View **do not have direct access** to Mediator. They interact with it only through special access objects:

```
┌─────────────┐                         ┌─────────────┐                         ┌─────────────┐
│ Interactor  │                         │  Mediator   │                         │     View    │
│             │                         │             │                         │             │
│ • logic     │                         │ • ViewModel │                         │ • UI        │
│ • data load │   ┌─────────────────┐   │ • inputI    │   ┌─────────────────┐   │ • events    │
│             │   │     AccessI     │   │ • inputV    │   │     AccessV     │   │             │
│  access ------->│ • viewModel(RW) │-->│             │<--│ • viewModel(R)  │<------- access  │
│             │   │ • inputV(R)     │   │             │   │ • inputI(R)     │   │             │
└─────────────┘   └─────────────────┘   └─────────────┘   └─────────────────┘   └─────────────┘
```

---

## Creating a Pack

Let's create a simple user profile screen.

### 1. Mediator

Mediator stores state (`ViewModel`) and defines interaction interfaces.

**Key difference from UIKit:** the `ViewModel` must conform to `ObservableObject`, and its properties must use `@Published` (or `@EZObservable` with `snapEZObservable()`). SwiftUI automatically updates the View when `ObservableObject` changes.

```swift
import EZSUIPackKit

final class ProfilePackM: EZSUIPackM {
    // MARK: - ViewModel (UI state)
    // Must be ObservableObject for automatic SwiftUI updates
    var viewModel: ViewModel
    @MainActor class ViewModel: ObservableObject {
        @Published var userName: String = ""
        @Published var isLoading: Bool = false
    }

    // MARK: - InputI (interface for Interactor, called from View)
    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
        func loadProfile()
        func logout()
    }

    // MARK: - InputV (interface for View, called from Interactor)
    // For SwiftUI views (structs), use a struct with closures
    // because structs cannot be weak references
    let inputV: InputV
    @MainActor struct InputV {
        var showAlert: (String) -> Void = { _ in }
    }

    // MARK: - Init
    // Free-form initializer — receives InputI and InputV directly
    init(inputI: InputI, inputV: InputV) {
        self.inputI = inputI
        self.inputV = inputV
        self.viewModel = .init()
    }
}
```

**Important:**
- `inputI` — an interface whose methods are **implemented by the Interactor** and **called by the View**
- `inputV` — since SwiftUI View is a `struct`, use a struct with closures instead of a protocol
- `ViewModel` — an `ObservableObject` class with `@Published` properties
- **I and V do not have direct access** to the Mediator, only through access objects

---

### 2. Interactor

The Interactor contains business logic and responds to SwiftUI lifecycle events.

**Key difference from UIKit:** the Interactor is a plain class (not `UIViewController`), and lifecycle is limited to `onAppear`/`onDisappear`.

```swift
import EZSUIPackKit

final class ProfilePackI: EZSUIPackI {
    // Access object to Mediator (NOT a direct reference to Mediator!)
    // Provides access only to viewModel and inputV
    let access = ProfilePackM.accessI

    // MARK: - Input for Mediator
    // Returns self as InputI (default when Mediator.InputI == Self)
    // func makeInput() -> Mediator.InputI { self }

    // MARK: - Lifecycle
    func didInitialize() {
        // Called after Pack is created and connected
    }

    func start() {
        // Called when Pack is ready to work
        loadProfile()
    }

    func onAppear() {
        // SwiftUI view appeared — refresh data if needed
    }

    func onDisappear() {
        // SwiftUI view disappeared — cancel tasks if needed
    }

    // MARK: - Business logic
    private func fetchProfile() {
        access.viewModel.isLoading = true

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            access.viewModel.userName = "John Doe"
            access.viewModel.isLoading = false
        }
    }
}

// MARK: - InputIProtocol
extension ProfilePackI: ProfilePackM.InputIProtocol {
    func loadProfile() {
        fetchProfile()
    }

    func logout() {
        // Handle logout
    }
}
```

---

### 3. View

A standard SwiftUI `View` with read-only access to `viewModel` and `inputI`.

```swift
import SwiftUI
import EZSUIPackKit

struct ProfileView: EZSUIPackV {
    // Access object to Mediator (NOT a direct reference to Mediator!)
    // Provides access only to viewModel and inputI
    let access = ProfilePackM.accessV

    // MARK: - Input for Mediator
    // Returns a struct with closures for InputV
    func makeInput() -> Mediator.InputV {
        .init(
            showAlert: { message in
                print("Alert: \(message)")
            }
        )
    }

    // MARK: - UI
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(viewModel.userName)
                    .font(.title)
            }

            Button("Load Profile") {
                inputI?.loadProfile()
            }

            Button("Log out") {
                inputI?.logout()
            }
        }
        .padding()
    }
}
```

**Note:** `viewModel` and `inputI` are convenience properties provided by `EZSUIPackViewProtocol`. They are equivalent to `access.viewModel` and `access.inputI`.

---

### 4. Assembling the Pack

Use `EZSUIPack` to assemble all three components in your SwiftUI body:

```swift
import SwiftUI
import EZSUIPackKit

struct ProfileScreen: View {
    var body: some View {
        EZSUIPack(
            interactor: { _ in ProfilePackI() },
            mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
            view: { _ in ProfileView() }
        )
    }
}
```

`EZSUIPack` creates all components, connects them, and manages their lifecycle. It uses `@StateObject` internally to survive SwiftUI re-renders.

---

## Passing External Data

### Via I.Context

Use `I.Context` when you need structured data from the Interactor available to the Mediator:

```swift
final class ProfilePackI: EZSUIPackI {
    let access = ProfilePackM.accessI
    let userId: String

    init(userId: String) {
        self.userId = userId
    }

    typealias Context = ProfileContext
    func makeContext() -> Context { .init(userId: userId) }
}

struct ProfileScreen: View {
    let userId: String

    var body: some View {
        EZSUIPack(
            interactor: { _ in ProfilePackI(userId: userId) },
            mediator: { inputI, inputV, context in
                ProfilePackM(inputI: inputI, inputV: inputV, userId: context.userId)
            },
            view: { _ in ProfileView() }
        )
    }
}
```

### Via Direct Closure Capture

The simplest approach when `I.Context` is not needed:

```swift
struct ProfileScreen: View {
    let userId: String

    var body: some View {
        EZSUIPack(
            interactor: { _ in ProfilePackI(userId: userId) },
            mediator: { inputI, inputV in
                ProfilePackM(inputI: inputI, inputV: inputV, userId: userId)
            },
            view: { _ in ProfileView() }
        )
    }
}
```

---

## Reactivity

SwiftUI updates automatically when `ObservableObject.objectWillChange` fires. Two options:

### @Published (standard)

```swift
@MainActor class ViewModel: ObservableObject {
    @Published var name = ""
    @Published var isLoading = false
}
```

### @EZObservable + snapEZObservable()

```swift
@MainActor class ViewModel: ObservableObject {
    @Published var name = ""
    @EZObservable var isLoading = false

    init() { snapEZObservable() }
}
```

`snapEZObservable()` bridges `@EZObservable` properties to `objectWillChange`, so SwiftUI responds to their changes just like `@Published`.

---

## InputV for SwiftUI Views

Since a SwiftUI `View` is a `struct`, it cannot conform to a `@MainActor protocol` with `weak` references. Use a struct with closures for `InputV`:

```swift
// In Mediator:
let inputV: InputV
@MainActor struct InputV {
    var showAlert: (String) -> Void = { _ in }
}

// In View:
func makeInput() -> Mediator.InputV {
    .init(showAlert: { message in /* ... */ })
}
```

If `InputV` is not needed, use `Void`:

```swift
// In Mediator:
let inputV: Void = ()
// No InputV protocols or structs needed

// In View:
// makeInput() has a default implementation returning ()
```

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| ViewModel is a struct, not a class | ViewModel must be a `class` conforming to `ObservableObject` |
| Using `@State` in View for shared data | Use `viewModel` from the access object instead |
| Storing Interactor in `@State`/`@ObservedObject` | `EZSUIPack` manages component lifecycle via `@StateObject` |
| Using `weak let` for InputV struct | `weak` is only for class types; use `let` for struct-based InputV |
| Accessing Mediator before `didInitialize()` | Access object is only connected after initialization |

---

## Next Steps

- [EZSUIPackKit Overview](../README.md) — core components and comparison with UIKit
- [EZUIPackKit QuickStart](../../EZUIPackKit/QuickStart/README.md) — UIKit equivalent guide
