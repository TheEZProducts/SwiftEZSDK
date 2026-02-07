# EZThreadSafety

`EZThreadSafety` is a `@propertyWrapper` that provides thread-safe access to a mutable value
via `get / set / update`. It is designed for **two usage modes**: synchronous and asynchronous.

The key implementation idea:

- In synchronous mode (`$value.get()/set()/update()` without `await`), everything is serialized through `EZRecursiveMutex` from `EZHelpersKit`.
- In asynchronous mode (`await $value.get()/set()/update()`), primary isolation is provided by an `actor` (`ActorIsolatedValue`): all async accesses enter sequentially.
- The same `EZRecursiveMutex` additionally protects access from async code to prevent races if synchronous calls happen in parallel.
- On older systems without `async/await`, `EZSendableWrapper` is used instead, which is also based on `EZRecursiveMutex`, so sync access remains thread-safe.

---

## API

```swift
@propertyWrapper
public struct EZThreadSafety<Value: Sendable>: Sendable {
    public var wrappedValue: Value { get set } // noasync (do not use in async)
    public var projectedValue: EZThreadSafety<Value> { get }

    // Async API (recommended in async code)

    /// Deprecated: inout access to the value.
    @available(*, deprecated,
               message: "Use update(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> R) async rethrows -> R instead")
    public func update<R: Sendable>(
        _ closure: @Sendable (inout Value) throws -> R
    ) async rethrows -> R

    /// Preferred: via EZAccess<Value>, works well with non-copyable values.
    public func update<R: Sendable>(
        _ closure: @Sendable (borrowing EZAccess<Value>) throws -> R
    ) async rethrows -> R where R: ~Copyable

    public func get() async -> Value
    public func set(_ value: Value) async

    // Sync API (for non-async context)

    /// Deprecated: inout access to the value.
    @available(*, deprecated,
               message: "Use update(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> R) instead")
    public func update<R>(
        _ closure: @Sendable (inout Value) throws -> R
    ) rethrows -> R

    /// Preferred sync variant: via EZAccess<Value>.
    public func update<R>(
        _ closure: @Sendable (borrowing EZAccess<Value>) throws -> R
    ) rethrows -> R where R: ~Copyable

    public func get() -> Value
    public func set(_ value: Value)

    public init(wrappedValue: Value)
    public init(_ value: Value)
}
```

---

## Behavior

- All operations (`get/set/update`) are atomic with respect to each other: each access fully completes before the next one begins.
- **Async mode:**
  - `await $property.update/get/set` enter `ActorIsolatedValue`, so async calls by themselves are executed sequentially (actor isolation).
  - Inside the actor, data access additionally goes through `EZRecursiveMutex` to avoid conflicting with possible synchronous accesses.
- **Sync mode:**
  - `$property.update/get/set` (without `await`) work on top of `EZRecursiveMutex` (via `EZSendableWrapper` or the same mutex base),
  - they can be safely called from any thread -- they simply acquire the lock and execute the provided block.
- **Mixed mode (sync + async):**
  - async code is serialized by the actor, sync code by the mutex,
  - both modes use the same `EZRecursiveMutex` for the value itself, so there are no races between sync and async access.

> In `async` code, use `$property` and `await`. Direct access via `wrappedValue` is marked as `noasync`
> and is intended primarily for synchronous contexts.

---

## Examples

### 1) Pure async (actor provides isolation)

```swift
struct Metrics: Sendable {
    @EZThreadSafety var count: Int = 0

    func inc() async {
        await $count.update { access in
            access.value += 1
        }
    }

    func value() async -> Int {
        await $count.get()
    }
}
```

### 2) Mixed mode (sync + async)

```swift
final class Store: @unchecked Sendable {
    @EZThreadSafety var items: [Int] = []

    // async path
    func addAsync(_ x: Int) async {
        await $items.update { access in
            access.value.append(x)
        }
    }

    // sync path (e.g. from non-async code)
    func countSync() -> Int {
        $items.get().count
    }
}
```
