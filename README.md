# SwiftEZSDK
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FTheEZProducts%2FSwiftEZSDK%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/TheEZProducts/SwiftEZSDK) [![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FTheEZProducts%2FSwiftEZSDK%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/TheEZProducts/SwiftEZSDK)

## Installation

### Swift Package Manager (available Xcode 11.2 and forward)
1. In Xcode, select File > Swift Packages > Add Package Dependency.
2. Follow the prompts using the https://github.com/TheEZProducts/SwiftEZSDK.git
3. Profit!

## Overview
EZSDK is a collection of small, focused Swift modules ("kits") that you can use independently or all-at-once.

- If you just want everything, depend on the **`All`** product.
- If you prefer a minimal footprint, depend on a specific kit.

> Note: Some kits are available only on specific Apple platforms (UIKit/AppKit/SwiftUI/ObjC runtime).

## Modules
### Stable
- **All** — umbrella product that re-exports the stable kits.
- **EZHelpersKit** — general-purpose helpers (thread-safety primitives, small utilities). *(some APIs may require newer Swift features)*
- **EZAssociatedKit** — associated-object helpers (ObjC runtime based).
- **EZAsyncKit** — async/concurrency helpers.
- **EZObservableKit** — lightweight observation system.
- **EZBuilderKit** — a set of protocols for implementing builders for any objects.
- **EZIMVPackKit** — platform-agnostic contracts for the IMV (Interactor-Mediator-View) architecture: mediator, interactor, and view protocols plus the abstract access protocols. Protocols only — no concrete types.
- **EZUIPackHelpersKit** — the standard IMV implementation: interactor access (`EZIMVPackAccessI`) and the single view access (`EZIMVPackAccessV`, created via `M.accessV`) used by both `EZUIPackKit` and `EZSUIPackKit`; the view access is conditionally a SwiftUI `DynamicProperty` for point-of-use invalidation.
- **EZTransitionKit** — custom view controller transition system with fluent API for navigation, tab bar, modal, and page transitions (iOS/tvOS/visionOS/macCatalyst).
- **EZUIPackKit** — UIKit toolkit for building UI using the IMV architecture. Includes interactors (`UIViewController`-based), mediators, platform-specific views, shared storage, and transition integration.
- **EZSUIPackKit** — SwiftUI toolkit for building UI using the IMV architecture. Provides SwiftUI-native interactors, mediators with `ObservableObject` view models, and a `EZSUIPack` container view.
- **EZSwiftUIBridgeKit** — convenient tools to embed UIKit/AppKit views in SwiftUI and embed SwiftUI views into platform views.
- **EZMacrosKit** — helpers and protocols for defining constant-storage property macros (implemented by the `EZMacros` macro target).

## Quick examples
### 1) Observe a value (EZObservableKit)
```swift
import EZObservableKit

final class Counter: Sendable {
    @EZObservable var value: Int = 0

    func start() {
        _ = $value.add { change in
            print("\(change.old) → \(change.new)")
        }
    }

    func inc() {
        _value.update { access in
            access.value += 1
        }
    }
}
```

### 2) Mutex-protected value (EZHelpersKit)
`EZLockingMutex` is the low-level building block behind `EZMutex` and `EZRecursiveMutex`. It stores a value
behind a concrete lock type and exposes it through `withLock { EZAccess<Value> }`, which also works well with
noncopyable (`~Copyable`) values.

```swift
import EZHelpersKit

func demoMutex() {
    // Most code should use the high-level helpers.
    let counter = EZMutex(0)
    let current = counter.withLock { access in
        access.value += 1
        return access.value
    }
    print(current)

    // Recursive variant when re-entrant locking is required.
    let list = EZRecursiveMutex([String]())
    list.withLock { $0.value.append("A") }
}
```

> Tip: If you need a custom lock implementation, use `EZLockingMutex<MyLock, Value>` directly.

### 3) Async rendezvous channel (EZAsyncKit)
`EZChannel` is a tiny async channel for passing values between tasks:
- `get()` suspends until a sender provides a value.
- `set(_:)` suspends until a receiver is waiting.
- `close()` unblocks all current and future waiters with `EZChannelError.closed`.

```swift
import EZAsyncKit

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
func demoChannel() async {
    let ch = EZChannel<Int>()

    let producer = Task {
        try await ch.set(1)   // waits for a receiver
        try await ch.set(2)
        ch.close()
    }

    let consumer = Task {
        do {
            while true {
                let v = try await ch.get() // waits for a sender
                print(v)
            }
        } catch is EZChannelError {
            // closed
        }
    }

    _ = await (producer.result, consumer.result)
}
```

### 4) Run work on an actor (EZAsyncKit)
These helpers make it easier to create tasks *on a specific actor* and to pass an explicit `isolated Self`.

```swift
import EZAsyncKit

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
func demoActorTasks() async throws {
    actor Store {
        var items: [String] = []
        func add(_ s: String) { items.append(s) }
    }

    let store = Store()

    // Explicit `isolated Self` parameter.
    let count = try await store.ezWithIsolation { actor in
        actor.add("A")
        return actor.items.count
    }
    print(count)

    // Create a Task whose operation runs on the actor.
    let task = store.ezTask { actor in
        actor.add("B")
        return actor.items
    }
    _ = try await task.value
}
```

### 5) Stoppable checked continuation (EZAsyncKit)
`ezWithCheckedStoppableContinuation` bridges callback-based APIs into async/await and is safe to resume
from a cancellation handler (it will throw `CancellationError()` if the task is cancelled).

```swift
import EZAsyncKit

@available(iOS 13.0, macOS 10.15, watchOS 6.0, tvOS 13.0, *)
func demoContinuation(api: API) async throws -> Int {
    try await ezWithCheckedStoppableContinuation { cont in
        api.fetchNumber { result in
            cont.resume(with: result)
        }
    }
}

protocol API {
    func fetchNumber(_ completion: @escaping (Result<Int, Error>) -> Void)
}
```

### 6) Bridge an observable into SwiftUI refresh (EZSwiftUIBridgeKit / EZObservableKit)
```swift
import SwiftUI
import EZObservableKit
import EZSwiftUIBridgeKit

@MainActor
final class VM: ObservableObject {
    @EZObservable var title: String = "Hello"

    init() {
        // Forward observable events into `objectWillChange`.
        snapEZObservable($title)
    }

    func setTitle(_ text: String) {
        title = text
    }
}

struct ContentView: View {
    @StateObject private var vm = VM()

    var body: some View {
        VStack {
            Text(vm.title)
            Button("Change") { vm.setTitle("Updated") }
        }
    }
}
```

### 7) Constant-storage property macros (macros kit)
EZSDK includes a universal macro implementation that can turn a stored property into a computed property
backed by a **constant** `let _name` storage. This helps avoid `Sendable` issues that can happen with
traditional stored `@propertyWrapper` variables in `class` types and global `static` storage.

### Example: define your own constant-storage macro
A constant-storage macro is typically declared in two forms (non-generic + generic) and uses the
universal implementation:
- `module: "EZMacros"`
- `type: "EZPropertyWrapperMacro"`

```swift
import EZMacrosKit

@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro LockedBox(option: Int = 0) =
    #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_CMP")

@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro LockedBox<T>(option: Int = 0) =
    #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_CMP")

public final class LockedBox<Value>: EZConstantPropertyWrapperProtocol {
    public typealias WrappedValue = Value
    public typealias ProjectedValue = Self

    public var wrappedValue: Value { get nonmutating set }
    public var projectedValue: Self { self }

    public init(wrappedValue: Value, option: Int = 0) {
        self.wrappedValue = wrappedValue
    }
}
```

### Example: use your macro
```swift
final class Example: Sendable {
    @LockedBox(option: 42) var value: Int = 123
    // Conceptually expands to:
    // var value: Int {
    //     _read { yield _value.wrappedValue }
    //     _modify { yield &_value.wrappedValue }
    // }
    //
    // var $value: LockedBox<Int>.ProjectedValue {
    //     _read { yield _value.projectedValue }
    // }
    //
    // // Extra macro arguments are appended after `wrappedValue`.
    // let _value: LockedBox<Int> = LockedBox(wrappedValue: 123, option: 42)

    func read() -> Int { $value.wrappedValue }

    func inc() {
        _value.wrappedValue += 1
    }
}
```

### Example: immutable (read-only) macro
If you want a getter-only property, make the storage conform to `EZConstantImmutablePropertyWrapperProtocol`.

```swift
@attached(accessor)
@attached(peer, names: prefixed(`$`), prefixed(`_`))
public macro ReadOnlyBox() =
    #externalMacro(module: "EZMacros", type: "EZPropertyWrapperMacro_CIP")

public struct ReadOnlyBox<Value>: EZConstantImmutablePropertyWrapperProtocol {
    public typealias WrappedValue = Value
    public typealias ProjectedValue = Self

    public let wrappedValue: Value
    public var projectedValue: Self { self }

    public init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
}

final class ReadOnlyExample: Sendable {
    @ReadOnlyBox var value: Int = 123
    // Conceptually expands to:
    // var value: Int {
    //     _read { yield _value.wrappedValue }
    // }
    //
    // var $value: ReadOnlyBox<Int>.ProjectedValue {
    //     _read { yield _value.projectedValue }
    // }
    //
    // let _value: ReadOnlyBox<Int> = ReadOnlyBox(wrappedValue: 123)

    func read() -> Int { value }
}
```

## Documentation

- [English](docs/en/README.md)
- [Русский](docs/ru/README.md)
