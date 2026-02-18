# EZUIPackKit Migration Guide

> Versions 2.x through 4.x had no breaking changes in EZUIPackKit.
> Migration is needed starting from **5.0.0**.

---

## 2-4 → 5

### Summary

`EZUIPackStorage` removed — Interactor became `UIViewController`. Struct-based actions (`EZUIPackActionProviderProtocol`) replaced with explicit associated types (`IActionProvider`, `VActionProvider`, `Storage`, `ViewModel`). Access control introduced (`AccessI`, `AccessV`). Specialized pack classes (`EZUINavigationPack`, `EZUITabBarPack`) unified into `EZUIPack` — container type now determined by interactor base class. Pack creation moved to factory `make()`.

### Mediator

**Before:**
```swift
class ProfilePackM: EZUIPackM {
    // EZUIPackM = EZUIPackMediatorProtocol & EZUIPackMediatorWithActionProviders & EZUIPackMediator
    // Data stored directly on mediator (no ViewModel concept)
    var name: String = ""

    // Actions were structs with closures, conforming to EZUIPackActionProviderProtocol
    var iActions = IAction()
    struct IAction: EZUIPackActionProviderProtocol {
        var load = {}
    }

    var vActions = VAction()
    struct VAction: EZUIPackActionProviderProtocol {
        var refresh = {}
    }
}
```

**After:**
```swift
class ProfilePackM: EZUIPackM {
    // EZUIPackM = EZUIPackMediatorProtocol & EZUIPackMediator

    // Explicit associated types (use Void if not needed)
    typealias IActionProvider = InputIProtocol?
    typealias VActionProvider = InputVProtocol?
    typealias Storage = Void
    typealias ViewModel = ViewModel

    weak var iActions: IActionProvider   // set by framework after setupActions()
    weak var vActions: VActionProvider
    var storage: Storage
    var viewModel: ViewModel

    // Data moved to ViewModel struct
    @MainActor struct ViewModel { var name: String = "" }
    @MainActor protocol InputIProtocol: AnyObject { func load() }
    @MainActor protocol InputVProtocol: AnyObject { func refresh() }

    required init() {
        iActions = nil
        vActions = nil
        viewModel = .init()
    }
}
```

**Key points:**
- `EZUIPackMediatorWithActionProviders` and `EZUIPackActionProviderProtocol` no longer exist
- Move shared data from direct mediator properties into the `ViewModel` struct
- Declare `IActionProvider`, `VActionProvider`, `Storage`, `ViewModel` as associated types
- Use `Void` for types you don't need (default implementations provided)
- `Storage` is exclusive data for the Interactor (accessed via `access.storage`)
- Action providers can be protocols (for class-based I/V) or structs with closures (for SwiftUI views)

### Interactor

**Before:**
```swift
class ProfilePackI: EZUIPackI {
    // EZUIPackI = EZUIPackInteractorProtocol (plain class, NOT a UIViewController)
    // EZUIPackStorage<I,M,V> was the actual UIViewController

    var mediator: ProfilePackM!

    func setupActions() {  // void — assigns closures to action structs
        iActions.load = { [weak self] in self?.load() }
    }

    private func load() { /* ... */ }
}
```

**After:**
```swift
class ProfilePackI: EZUIPackI {
    // EZUIPackI = EZUIPackInteractor & EZUIPackInteractorProtocol
    // Interactor IS a UIViewController now

    var access: Mediator.AccessI!  // replaces direct mediator reference

    // setupActions() now returns the action provider
    func setupActions() -> Mediator.IActionProvider {
        self
    }
}
// When returning self, conform to the action protocol:
extension ProfilePackI: ProfilePackM.InputIProtocol {
    func load() { /* ... */ }
}
```

**Key points:**
- Interactor is now `UIViewController` — remove manual VC embedding via `EZUIPackStorage`
- Replace `var mediator: Mediator!` with `var access: Mediator.AccessI!`
- `setupActions()` now **returns** the action provider instead of assigning closures
- When returning `self`, conform to the mediator's action protocol
- `init(mediator:)` removed — interactor created via `init(pack:customData:)`

### View

**Before:**
```swift
class ProfileIOSV: EZUIPackV {
    var mediator: ProfilePackM!

    func setupActions() {  // void — assigns closures to action structs
        vActions.refresh = { [weak self] in self?.refreshUI() }
    }

    private func refreshUI() { /* ... */ }
}
```

**After (protocol-based, UIKit class view):**
```swift
class ProfileIOSV: EZUIPackV {
    var access: Mediator.AccessV!

    func setupActions() -> Mediator.VActionProvider? {
        self
    }
}
extension ProfileIOSV: ProfilePackM.InputVProtocol {
    func refresh() { /* ... */ }
}
```

**After (struct-based, SwiftUI view — only correct option for struct views):**

When V is a SwiftUI view (struct), it cannot be a weak reference. Use a struct with closures for `VActionProvider`:
```swift
// In mediator — declare struct instead of protocol:
var vActions: InputV = .init(refresh: {})
struct InputV {
    var refresh: () -> Void
}

// In SwiftUI view:
func setupActions() -> Mediator.VActionProvider? {
    .init(refresh: { /* ... */ })
}
```

**Key points:**
- Replace `var mediator` with `var access: Mediator.AccessV!`
- `setupActions()` returns `Mediator.VActionProvider?` instead of assigning closures
- For UIKit views (classes): return `self` and conform to action protocol
- For SwiftUI views (structs): use struct with closures as `VActionProvider`

### Pack Creation

**Before:**
```swift
// Specialized pack types: EZUINavigationPack, EZUITabBarPack, EZUIPack
typealias ProfilePack = EZUINavigationPack<ProfilePackI, ProfilePackM, ProfilePackV>

let pack = ProfilePack()
// EZUIPackStorage was the UIViewController
```

**After:**
```swift
// Unified to EZUIPack — container type determined by interactor base class:
// EZUIPackI (plain), EZUINavigationPackI (navigation), EZUITabBarPackI (tab bar)
typealias ProfilePack = EZUIPack<ProfilePackI, ProfilePackM, ProfilePackV>

// Interactor IS the UIViewController — make() returns it directly
let interactor = ProfilePack.make()
navigationController.pushViewController(interactor, animated: true)
```

### Accessing Data (cheat sheet)

| Before | After |
|---|---|
| `mediator.someProperty` (direct) | `viewModel.someProperty` |
| `iActions.load()` (struct closure) | `iActions?.load()` (protocol method, in V) |
| `vActions.refresh()` (struct closure) | `vActions?.refresh()` (protocol method, in I) |
| `var mediator: Mediator!` | `var access: Mediator.AccessI!` / `.AccessV!` |
| `pack.storage` (UIViewController) | Interactor is the UIViewController |
| `EZUINavigationPack` / `EZUITabBarPack` | `EZUIPack` + interactor base class |

---

## 5 → 6

### Summary

`IActionProvider`/`VActionProvider` replaced with `InputI`/`InputV`. `Storage` removed — Interactor now stores its own data. `setupActions()` removed — inputs provided via context system (`makeContext()`). Mediator gets explicit `init(contextI:contextV:)`. Access objects became class-based (`let`) with `AccessMap` support. `.transit` renamed to `.ezTransit`.

### Transit Rename

```swift
// Before:
self.transit.navigationPush(otherVC).transit()

// After:
self.ezTransit.navigationPush(otherVC).transit()
```

Entry-point properties `.transit` on `UIViewController` and `EZContainerView` renamed to `.ezTransit`. The execution method `.transit()` on transition chains was **not** renamed.

### Mediator

**Before:**
```swift
class ProfilePackM: EZUIPackM {
    typealias IActionProvider = InputIProtocol?
    typealias VActionProvider = InputVProtocol?
    typealias Storage = Void
    typealias ViewModel = ViewModel

    weak var iActions: IActionProvider
    weak var vActions: VActionProvider
    var storage: Storage
    var viewModel: ViewModel

    @MainActor struct ViewModel { var name: String = "" }
    @MainActor protocol InputIProtocol: AnyObject { func load() }
    @MainActor protocol InputVProtocol: AnyObject { func refresh() }

    required init() {
        iActions = nil
        vActions = nil
        viewModel = .init()
    }
}
```

**After:**
```swift
class ProfilePackM: EZUIPackM {
    var viewModel: ViewModel
    @MainActor struct ViewModel { var name: String = "" }

    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject { func load() }

    weak let inputV: InputVProtocol?
    @MainActor protocol InputVProtocol: AnyObject { func refresh() }

    required init(contextI: BaseContextI, contextV: BaseContextV) {
        viewModel = contextI.viewModel
        inputI = contextI.actions
        inputV = contextV.actions
    }
}
```

**Key points:**
- Remove `IActionProvider`/`VActionProvider`/`Storage` — use `InputI`/`InputV`/`ViewModel` directly
- `Storage` removed entirely — Interactor should store its own exclusive data as regular properties
- Replace `required init()` with `required init(contextI:contextV:)`
- `contextI.actions` = InputI, `contextI.viewModel` = initial ViewModel, `contextV.actions` = InputV
- Use `weak let` instead of `weak var` for input references

### Interactor

**Before:**
```swift
class ProfilePackI: EZUIPackI {
    var access: Mediator.AccessI!  // set by framework

    func setupActions() -> Mediator.IActionProvider { self }
}
```

**After:**
```swift
class ProfilePackI: EZUIPackI {
    let access = ProfilePackM.accessI  // now let, initialized statically

    func makeContext() -> Mediator.ContextI {
        .init(actions: self, viewModel: .init())
    }
}
```

**Key points:**
- `access` is now `let`, created via `ProfilePackM.accessI` (static factory)
- Replace `setupActions()` with `makeContext()` returning `Mediator.ContextI`
- Context wraps both `actions` (= InputI) and `viewModel` (initial state)
- Mediator is **not yet accessible** when `makeContext()` is called (unlike `setupActions()` which had mediator available)

### View

**Before:**
```swift
class ProfileIOSV: EZUIPackV {
    var access: Mediator.AccessV!

    func setupActions() -> Mediator.VActionProvider? { self }
}
```

**After:**
```swift
class ProfileIOSV: EZUIPackV {
    let access = ProfilePackM.accessV  // now let, initialized statically

    func makeContext() -> Mediator.ContextV {
        .init(actions: self)
    }
}
```

**Key points:**
- `access` is now `let`, created via `ProfilePackM.accessV`
- Replace `setupActions()` with `makeContext()` returning `Mediator.ContextV`
- Mediator is **not yet accessible** when `makeContext()` is called

### Pack Creation

No changes — `ProfilePack.make()` still works.

### Accessing Data (cheat sheet)

| Before | After |
|---|---|
| `access.iActions` (in V) | `access.inputI` or `inputI` |
| `access.vActions` (in I) | `access.inputV` or `inputV` |
| `access.storage` (in I) | removed — store data as Interactor properties |
| `access.viewModel` | `access.viewModel` or `viewModel` (same) |
| `.transit` | `.ezTransit` |

---

## 6 → 7

### Summary

Context wrappers (`ContextI`/`ContextV`) removed. I and V provide inputs directly via `makeInput()`. Mediator has a free-form initializer. Pack creation uses `EZPackMaker.make(interactor:mediator:view:)` with explicit closures. Interactor can still provide extra context via `associatedtype Context` + `makeContext()`, but it's now separate from the input system.

### Mediator

**Before:**
```swift
class ProfilePackM: EZUIPackM {
    var viewModel: ViewModel
    @MainActor struct ViewModel { var name: String = "" }

    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject { func load() }

    weak let inputV: InputVProtocol?
    @MainActor protocol InputVProtocol: AnyObject { func refresh() }

    required init(contextI: BaseContextI, contextV: BaseContextV) {
        viewModel = contextI.viewModel
        inputI = contextI.actions
        inputV = contextV.actions
    }
}
```

**After:**
```swift
class ProfilePackM: EZUIPackM {
    var viewModel: ViewModel
    @MainActor struct ViewModel { var name: String = "" }

    weak let inputI: InputIProtocol?
    @MainActor protocol InputIProtocol: AnyObject { func load() }

    weak let inputV: InputVProtocol?
    @MainActor protocol InputVProtocol: AnyObject { func refresh() }

    // Free-form init — receives InputI and InputV directly
    init(inputI: InputI, inputV: InputV) {
        self.inputI = inputI
        self.inputV = inputV
        self.viewModel = .init()
    }
}
```

**Key points:**
- Remove `required init(contextI:contextV:)` — no longer a protocol requirement
- Replace with any custom `init` receiving `InputI` and `InputV` directly (+ any extra params)
- ViewModel is no longer passed from outside — initialize it in `init`
- `ContextI`/`ContextV`/`BaseContextI`/`BaseContextV` types no longer exist

### Interactor

**Before:**
```swift
class ProfilePackI: EZUIPackI {
    let access = ProfilePackM.accessI

    func makeContext() -> Mediator.ContextI {
        .init(actions: self, viewModel: .init())
    }
}
```

**After:**
```swift
class ProfilePackI: EZUIPackI {
    let access = ProfilePackM.accessI

    func makeInput() -> Mediator.InputI { self }
    // Default implementation provided when Mediator.InputI == Self — can be omitted
}
```

Context still exists but is now a separate concept on the Interactor:

```swift
class ProfilePackI: EZUIPackI {
    let access = ProfilePackM.accessI

    // associatedtype Context = Void by default — no typealias needed when Void
    // Override only if you need to pass extra data to Mediator:
    typealias Context = ProfileContext  // only declare when Context != Void
    func makeContext() -> Context { .init(userId: userId) }
}
```

The context is passed as 3rd parameter to the mediator closure in `EZPackMaker.make()`.

**Key points:**
- Replace `makeContext() -> Mediator.ContextI` with `makeInput() -> Mediator.InputI`
- Default implementation when `Mediator.InputI == Self` or `Mediator.InputI == Void`
- `makeContext()` still exists but returns `I.Context` (not `Mediator.ContextI`), defaults to `Void`

### View

**Before:**
```swift
class ProfileIOSV: EZUIPackV {
    let access = ProfilePackM.accessV

    func makeContext() -> Mediator.ContextV {
        .init(actions: self)
    }
}
```

**After:**
```swift
class ProfileIOSV: EZUIPackV {
    let access = ProfilePackM.accessV

    func makeInput() -> Mediator.InputV { self }
    // Default implementation provided when Mediator.InputV == Self — can be omitted
}
```

**Key points:**
- Replace `makeContext()` with `makeInput()` returning `Mediator.InputV`
- Default implementation when `Mediator.InputV == Self` or `Mediator.InputV == Void`

### Pack Creation

**Before:**
```swift
typealias ProfilePack = EZUIPack<ProfilePackI, ProfilePackM, ProfilePackV>
let interactor = ProfilePack.make()
```

**After:**
```swift
enum ProfilePack {
    @MainActor
    static func make() -> ProfilePackI {
        EZPackMaker.make(
            interactor: { ProfilePackI() },
            mediator: { inputI, inputV in ProfilePackM(inputI: inputI, inputV: inputV) },
            view: { ProfilePackV() }
        )
    }
}
```

### Passing External Data

**Before:** external data flowed through `ContextI` into mediator's `init(contextI:contextV:)`.

**After:** two approaches:

**Via I.Context** (structured data from Interactor, received as 3rd parameter in mediator closure):
```swift
// Interactor defines Context:
class ProfilePackI: EZUIPackI {
    // ...
    typealias Context = ProfileContext  // only declare when Context != Void
    func makeContext() -> Context { .init(userId: userId) }
}

// Context received as 3rd parameter in mediator closure:
enum ProfilePack {
    @MainActor
    static func make(userId: String) -> ProfilePackI {
        EZPackMaker.make(
            interactor: { ProfilePackI(userId: userId) },
            mediator: { inputI, inputV, context in
                ProfilePackM(inputI: inputI, inputV: inputV, userId: context.userId)
            },
            view: { ProfilePackV() }
        )
    }
}
```

**Via direct closure capture** (simplest, when I.Context is not needed):
```swift
enum ProfilePack {
    @MainActor
    static func make(userId: String) -> ProfilePackI {
        EZPackMaker.make(
            interactor: { ProfilePackI(userId: userId) },
            mediator: { inputI, inputV in
                ProfilePackM(inputI: inputI, inputV: inputV, userId: userId)
            },
            view: { ProfilePackV() }
        )
    }
}
```

### Quick Conversion Checklist

1. **Mediator**: `init(contextI:contextV:)` → `init(inputI:inputV:)`, init ViewModel inside
2. **Interactor**: `makeContext() -> Mediator.ContextI` → `makeInput() -> Mediator.InputI`
3. **View**: `makeContext() -> Mediator.ContextV` → `makeInput() -> Mediator.InputV`
4. **Pack creation**: `ProfilePack.make()` → `EZPackMaker.make(interactor:mediator:view:)`
5. Delete all `ContextI`/`ContextV`/`BaseContextI`/`BaseContextV` references
