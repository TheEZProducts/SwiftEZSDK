# AsyncStream.Continuation helpers (EZ*)

A set of convenience methods for managing `AsyncStream.Continuation`:
- automatic `finish()` on anchor deinitialization;
- timeout for stream completion;
- (optionally) binding the continuation's lifecycle to an object via `EZAssociatedKit`.

> Availability:
> - `ezSetTimeout(duration:)` -- macOS 13+, iOS 16+, watchOS 9+, tvOS 16+
> - everything else -- macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+
> Some methods are only available when `canImport(EZAssociatedKit) && canImport(ObjectiveC)`.

---

## API

```swift
extension AsyncStream.Continuation {
    public func ezSetTimeout(duration: Duration) // macOS13+/iOS16+...

    public func ezMakeAnchor() -> EZDeinitAnchor

    @discardableResult
    public func ezMakeAnchor(_ action: (EZDeinitAnchor) -> Void) -> Self

    // Only when canImport(EZAssociatedKit) && canImport(ObjectiveC)
    @discardableResult
    public func ezSnapToObject(_ object: AnyObject) -> Self
}
```

---

## Behavior

- `ezMakeAnchor()` creates an `EZDeinitAnchor` that calls `finish()` when the anchor is deinitialized.
- `ezMakeAnchor(_:)` -- does the same but immediately passes the anchor to a closure and returns `self`.
- `ezSetTimeout(duration:)` starts a `Task` that sleeps for the specified duration and then calls `finish()`.
- `ezSnapToObject(_:)` *(optional)* binds the anchor to an object. When the object is deinitialized, the stream finishes (`finish()`).

---

## Examples

### 1) Finishing the stream on owner deinitialization (manual anchor storage)

```swift
final class Producer {
    private var anchor: EZDeinitAnchor?
    private var continuation: AsyncStream<Int>.Continuation?

    func makeStream() -> AsyncStream<Int> {
        AsyncStream { continuation in
            self.continuation = continuation
            self.anchor = continuation.ezMakeAnchor() // on Producer deinit -> finish()
        }
    }
}
```

### 2) Timeout for stream completion

```swift
let stream = AsyncStream<Int> { continuation in
    continuation.ezSetTimeout(duration: .seconds(2))

    Task.detached {
        for i in 0..<10 {
            continuation.yield(i)
            try? await Task.sleep(nanoseconds: 300_000_000)
        }
    }
}

Task {
    for await value in stream {
        print(value)
    }
    print("stream finished")
}
```

> Conditional example (only with EZAssociatedKit + ObjectiveC):
> `continuation.ezSnapToObject(self)` -- finish the stream on deinitialization of `self`.
