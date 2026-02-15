# MainActor.ezUnsafeRun

`MainActor.ezUnsafeRun` is a utility for **synchronously** executing a `@MainActor`-annotated closure
from a `nonisolated` context **without hopping to the MainActor executor**.

> Warning: this is an **unsafe** API. It uses `unsafeBitCast` and intentionally bypasses the actor hop.
> It is useful for low-level optimizations/integrations, but requires caution.

---

## API

```swift
extension MainActor {
    public static func ezUnsafeRun<Result>(
        action: @MainActor @escaping @Sendable () -> Result
    ) -> Result

    public static func ezUnsafeRun<Result>(
        action: @MainActor @escaping @Sendable () throws -> Result
    ) throws -> Result
}
```

---

## Behavior

- Executes `action` **synchronously**, returning `Result` (or rethrowing).
- **Does not guarantee** that the call actually happens on the MainActor executor.
- No `await`/scheduling on the actor takes place -- this is a direct call after `unsafeBitCast`.

Use this method only if you are **confident** that you are calling it from the correct place
(for example, you are already on the main thread/executor, or you do not care about isolation and understand the risks).

---

## Examples

### 1) Synchronously obtaining a value from a `@MainActor` context

```swift
@MainActor func currentTitle() -> String { "Hello" }

let title = MainActor.ezUnsafeRun {
    currentTitle()
}

print(title)
```

### 2) Variant with `throws`

```swift
enum MyError: Error { case failed }

@MainActor func makeValue() throws -> Int {
    throw MyError.failed
}

do {
    let value = try MainActor.ezUnsafeRun {
        try makeValue()
    }
    print(value)
} catch {
    print("error:", error)
}
```
