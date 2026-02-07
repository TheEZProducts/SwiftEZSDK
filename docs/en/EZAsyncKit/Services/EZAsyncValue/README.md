# EZAsyncValue

`EZAsyncValue` is an asynchronous value (`actor`) that can be awaited from multiple tasks and resolved via a continuation.
Conceptually it is similar to a "promise / future": a value (or error) is set through `EZActionContinuation`, and readers obtain it via `await get()`.

Typical use cases:
- bridging from callback APIs to `async/await`;
- a shared "promise-like" value across multiple tasks;
- optional **value updates over time** through the same container (`isAbleToUpdating`).

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public actor EZAsyncValue<Value: Sendable>: Sendable {
    public init(
        isAbleToUpdating: Bool = false,
        action: (EZActionContinuation<Value>) -> Void
    )

    public func get() async throws -> Value

    public static func makeValue(
        isAbleToUpdating: Bool = false
    ) -> (value: EZAsyncValue, continuation: EZActionContinuation<Value>)
}

@available(macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0, *)
public final class EZActionContinuation<T: Sendable>: Sendable {
    public init(
        isReusable: Bool = false,
        action: @escaping @Sendable (Result<T, Error>) async -> Void
    )

    public func resume(with result: Result<T, Error>)
    public func resume(returning value: T)
    public func resume(throwing error: Error)
}
```

---

## Behavior

- **Waiting:** `get()` suspends when no result is available until the continuation is `resume(...)`d. Before suspending, `Task.checkCancellation()` is called, so a cancelled task will complete with `CancellationError`.
- **Caching:** once the result is set, `get()` returns it immediately without suspending again.
- **Multiple readers:** several tasks can simultaneously await `get()` -- all current waiters are woken by a single `resume(...)`.
- **Errors:** if `.failure` is set, all `get()` calls will throw the corresponding `Error`.
- **Default mode (`isAbleToUpdating == false`):**
  - the continuation behaves as one-shot;
  - the first successful or error completion wakes all current waiters and locks in the result inside `EZAsyncValue`;
  - subsequent `resume(...)` calls are ignored.
- **Update mode (`isAbleToUpdating == true`):**
  - the continuation becomes reusable (`isReusable = true`);
  - each new `resume(...)` updates the stored `result` inside `EZAsyncValue`;
  - tasks that call `get()` **after** an update immediately receive the latest version of the value/error;
  - tasks that have already completed `get()` are not automatically re-notified -- to read the new value, call `get()` again.

---

## Usage Examples

### 1) Bridging from a completion handler (one-shot)

```swift
func fetchNumber(completion: @escaping (Result<Int, Error>) -> Void) {
    // ... any callback implementation
}

let asyncValue = EZAsyncValue<Int> { continuation in
    fetchNumber { result in
        continuation.resume(with: result)
    }
}

let number = try await asyncValue.get()
```

---

### 2) Updatable value (`isAbleToUpdating`)

```swift
let value = EZAsyncValue<Int>(isAbleToUpdating: true) { continuation in
    continuation.resume(returning: 1)
    continuation.resume(returning: 2) // overwrites stored result
}

// Later, in another task:
let latest = try await value.get() // 2
```

---

### 3) Using `makeValue`

```swift
let (value, continuation) = EZAsyncValue<Int>.makeValue()

Task {
    // somewhere later
    continuation.resume(returning: 42)
}

let answer = try await value.get() // 42
```
