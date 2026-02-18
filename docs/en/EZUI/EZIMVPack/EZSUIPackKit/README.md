# EZSUIPackKit

A SwiftUI module for building UI using the **IMV (Interactor-Mediator-View)** architecture. Provides the same separation of logic, state, and presentation as EZUIPackKit, but with native SwiftUI components.

**Platforms:** iOS 14+, macOS 11+, tvOS 14+, watchOS 7+, visionOS

---

## Quick Start

### 1. Mediator

The mediator stores state via a view model and defines interfaces for interactor and view communication. When ViewModel conforms to `ObservableObject`, SwiftUI updates happen automatically.

```swift
import EZSUIPackKit

class ProfilePackM: EZSUIPackM {
    var viewModel: ViewModel
    @MainActor class ViewModel: ObservableObject {
        @Published var name = ""
        @Published var isLoading = false
    }

    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject {
        func loadProfile()
    }

    let inputV: Void = ()

    init(inputI: InputI, inputV: InputV) {
        self.inputI = inputI
        self.inputV = inputV
        self.viewModel = .init()
    }
}
```

### 2. Interactor

The interactor holds business logic and reacts to SwiftUI lifecycle events.

```swift
class ProfilePackI: EZSUIPackI {
    let access = ProfilePackM.accessI

    func makeInput() -> Mediator.InputI { self }

    func start() {
        loadProfile()
    }

    func onAppear() {
        refreshProfileIfNeeded()
    }
}

extension ProfilePackI: ProfilePackM.InputIProtocol {
    func loadProfile() {
        viewModel.isLoading = true
        // ... load data, update viewModel
    }

    private func refreshProfileIfNeeded() {
        // ...
    }
}
```

### 3. View

A standard SwiftUI `View` with access to `viewModel` (RW) and `inputI` (R).

```swift
import SwiftUI

struct ProfileView: EZSUIPackV {
    let access = ProfilePackM.accessV

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                Text(viewModel.name)
            }
            Button("Reload") { inputI.loadProfile() }
        }
    }
}
```

### 4. Combining into a Pack

Use `EZSUIPack` to assemble all three components:

```swift
struct ProfileScreen: View {
    var body: some View {
        EZSUIPack(
            interactor: { ProfilePackI() },
            mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
            view: { ProfileView() }
        )
    }
}
```

When the interactor uses a custom `Context`, pass the full closure:

```swift
EZSUIPack(
    interactor: { MyPackI() },
    mediator: { inputI, inputV, context in MyPackM(inputI: inputI, inputV: inputV, context: context) },
    view: { MyView() }
)
```

---

## Core Components

| Component | Description |
|-----------|-------------|
| `EZSUIPack` | SwiftUI view that assembles and manages an IMV pack |
| `EZSUIPackI` / `EZSUIPackInteractorProtocol` | Interactor protocol with `onAppear`/`onDisappear` lifecycle |
| `EZSUIPackM` / `EZSUIPackMediator` | Base mediator class (ViewModel optionally conforms to `ObservableObject`) |
| `EZSUIPackV` / `EZSUIPackViewProtocol` | View protocol combining `View` + `EZIMVPackViewProtocol` |

---

## Differences from EZUIPackKit

| Feature | EZUIPackKit (UIKit) | EZSUIPackKit (SwiftUI) |
|---------|--------------------|-----------------------|
| Interactor base | `UIViewController` | Plain class |
| Lifecycle | `didCreate`, `willOpen`, `didOpen`, `willClose`, `didClose` | `onAppear`, `onDisappear` |
| View | `UIView` or SwiftUI via bridge | Native SwiftUI `View` |
| Pack creation | `EZPackMaker.make()` / `EZUIPack.make()` | `EZSUIPack(...)` in SwiftUI body |
| View model updates | Manual via `packBridge` | Automatic via `ObservableObject` |

---

## Useful Links

- [Quick Start Guide](QuickStart/README.md) — step-by-step tutorial
- [EZUIPackKit docs](../EZUIPackKit/README.md) — UIKit equivalent
- [EZIMVPackKit](../../../../../Sources/EZUI/EZIMVPack/EZIMVPackKit/) — shared base protocols
- [Source Code](../../../../../Sources/EZUI/EZIMVPack/EZSUIPackKit/) — module implementation
