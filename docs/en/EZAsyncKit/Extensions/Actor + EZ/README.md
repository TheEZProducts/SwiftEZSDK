# Actor extensions (EZ*)

A set of utilities for convenient work with `actor` and tasks where the operation takes `(isolated Self)`.

> Availability:
> - `isIsolated` and `ezTaskImmediate` -- macOS 26+, iOS 26+, watchOS 26+, tvOS 26+
> - everything else -- macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
extension Actor {
    public var isIsolated: Bool // macOS/iOS/watchOS/tvOS 26+

    public func ezWithIsolation<T>(
        _ body: @Sendable (isolated Self) async throws -> T
    ) async rethrows -> T

    @discardableResult
    public func ezTask<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error>

    @discardableResult
    public func ezTaskImmediate<R>( // macOS/iOS/watchOS/tvOS 26+
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error>

    @discardableResult
    public func ezTaskDetached<R>(
        name: String? = nil,
        priority: TaskPriority? = nil,
        operation: @Sendable @escaping (isolated Self) async throws -> R
    ) -> Task<R, Error>

    public func ezUnsafeRun<R>(_ body: @escaping (isolated Self) throws -> R) throws -> R
    public func ezUnsafeRun<R>(_ body: @escaping (isolated Self) -> R) -> R
}
```

---

## Behavior

- `ezWithIsolation(...)`: executes `body` within the actor's isolation (inside the actor's `await` context).
- `ezTask(...)`: creates a `Task` that will execute `operation` within this actor's isolation.
- `ezTaskImmediate(...)` (26+): creates a `Task.immediate` that can start immediately (when allowed by the runtime rules).
- `ezTaskDetached(...)`: creates a `Task.detached`, but the operation itself is still executed within the actor's isolation (a hop to the actor happens inside the task).
- `isIsolated` (26+): returns `true` if the code is currently executing on this actor's executor (useful for debugging/assertions).
- `ezUnsafeRun(...)`: **unsafe** synchronous execution of a body that takes `isolated Self`, via `unsafeBitCast`. Use only if you understand the consequences (it does not "hop" to the actor executor and does not perform any awaits -- this is specifically an unsafe bypass).

---

## Examples

### 1) Scheduling work on an actor from a non-async context

```swift
actor Counter {
    private var value = 0
    func inc() { value += 1 }
    func get() -> Int { value }
}

let counter = Counter()

// Start increment without explicit await at call site
let task = counter.ezTask { isolatedSelf in
    isolatedSelf.inc()
    return isolatedSelf.get()
}

let result = try await task.value
print(result)
```

### 2) Multiple parallel tasks, safely serialized by the actor

```swift
actor Store {
    private var items: [Int] = []
    func add(_ x: Int) { items.append(x) }
    func snapshot() -> [Int] { items }
}

let store = Store()

let tasks = (0..<10).map { i in
    store.ezTaskDetached { isolatedSelf in
        isolatedSelf.add(i)
    }
}

for t in tasks { _ = try await t.value }

let values = try await store.snapshot()
print(values.count) // 10
```
