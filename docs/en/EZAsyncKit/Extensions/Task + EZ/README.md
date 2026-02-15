# Task Anchors & Cancellation Helpers

This set of extensions helps:
- automatically **cancel a `Task` on deinitialization** (via `EZDeinitAnchor`);
- **bind a `Task` to the lifecycle of an object** (optionally via `EZAssociatedKit`);
- correctly **propagate cancellation of the current task** into a `Task` (via `ezSnapToCurrentTask`).

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+
> Some methods are only available when `canImport(EZAssociatedKit) && canImport(ObjectiveC)`.

---

## API

```swift
extension EZDeinitAnchor {
    public convenience init<Success, Failure>(task: Task<Success, Failure>)
}

extension Task {
    public func ezMakeAnchor() -> EZDeinitAnchor

    @discardableResult
    public func ezMakeAnchor(_ action: (EZDeinitAnchor) -> Void) -> Self

    // Only when canImport(EZAssociatedKit) && canImport(ObjectiveC)
    @discardableResult
    public func ezSnapToObject(_ object: AnyObject) -> Self
}

extension Task {
    public func ezSnapToCurrentTask(
        isolation: isolated (any Actor)? = #isolation
    ) async throws -> Success
}
```

---

## Behavior

### `EZDeinitAnchor(task:)`
Creates an `EZDeinitAnchor` that will call `task.cancel()` when the anchor is deinitialized.

### `Task.ezMakeAnchor() / ezMakeAnchor(_:)`
- `ezMakeAnchor()` -- returns an anchor for this task.
- `ezMakeAnchor(_:)` -- does the same but immediately passes the anchor to a closure (convenient for storage/binding) and returns `self` for chaining.

### `Task.ezSnapToObject(_:)` *(optional)*
If `EZAssociatedKit` and `ObjectiveC` are available, binds the anchor to an object (via associated storage).
Result: when the object is deinitialized, the anchor is deinitialized, and the task is cancelled.

### `Task.ezSnapToCurrentTask(...)`
Awaits the task's result, but if the **current** (outer) task is cancelled, automatically calls `cancel()` on this task.

---

## Examples

### 1) Cancelling a task on owner deinitialization (manual anchor storage)

```swift
final class Loader {
    private var anchor: EZDeinitAnchor?

    func start() {
        let task = Task {
            try await fetchSomething()
        }

        // While Loader is alive — anchor is alive — task is not auto-cancelled
        anchor = task.ezMakeAnchor()
    }
}
```

### 2) Propagating cancellation of the current task into a `Task`

```swift
func loadWithCancellationPropagation() async throws -> Data {
    let task = Task<Data, Error> {
        try await fetchData()
    }

    // If the calling task is cancelled — task.cancel() is called automatically
    return try await task.ezSnapToCurrentTask()
}
```

> Conditional example (only with EZAssociatedKit + ObjectiveC):
> `Task { ... }.ezSnapToObject(self)` -- binding to the lifecycle of `self`.
