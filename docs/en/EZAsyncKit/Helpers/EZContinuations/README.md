# Continuations (EZ*)

A set of base types for unified continuation handling and safe resume:

- `EZContinuationProtocol` -- a common protocol with `resume(returning:) / resume(throwing:)` + convenient helpers.
- `EZContinuationError` -- a standard error for the case when the continuation owner was deinitialized.
- `EZActionContinuation` -- a continuation that resumes via an async callback (one-shot).
- `EZSafeContinuation` -- a safe wrapper around `CheckedContinuation` that guarantees **single resume**
  and allows resuming even if the actual `CheckedContinuation` is set later.

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## EZContinuationError

```swift
public enum EZContinuationError: String, LocalizedError, Sendable {
    case wasDeinit = "Was deallocated"
}
```

Used as the default error on `deinit` if the continuation was not explicitly resumed.

---

## EZContinuationProtocol

```swift
public protocol EZContinuationProtocol<T, E>: Sendable where E: Error {
    associatedtype T
    associatedtype E

    func resume(throwing error: E)
    func resume(returning value: T)
}
```

### Helpers

Convenient overloads are available:
- `resume(with: Result<...>)` (including when `E == any Error`);
- `resume()` for the `T == ()` case.

Additionally, `CheckedContinuation` and `UnsafeContinuation` automatically conform to the protocol:

```swift
extension CheckedContinuation: EZContinuationProtocol {}
extension UnsafeContinuation: EZContinuationProtocol {}
```

---

## EZActionContinuation

```swift
public final class EZActionContinuation<T: Sendable>: Sendable, EZContinuationProtocol {
    public init(action: @escaping @Sendable (Result<T, Error>) async -> Void)

    public func resume(with result: Result<T, Error>)
    public func resume(returning value: T)
    public func resume(throwing error: Error)
}
```

- One-shot: after the first `resume(...)`, the callback is cleared.
- Resume invokes the provided `action` inside a `Task`.
- If the object is deinitialized before `resume(...)`, it automatically resumes with `EZContinuationError.wasDeinit`.

**Example:**
```swift
let cont = EZActionContinuation<Int> { result in
    print(result)
}

cont.resume(returning: 10) // prints success(10)
```

---

## EZSafeContinuation

```swift
public final class EZSafeContinuation<T: Sendable>: Sendable, EZContinuationProtocol {
    public init(continuation: CheckedContinuation<T, Error>? = nil)

    public func set(continuation: CheckedContinuation<T, Error>?)
    public func resume(with result: Result<T, Error>)
    public func resume(returning value: T)
    public func resume(throwing error: Error)

    public var result: Result<T, Error>? { get }
}
```

### Behavior

- Guarantees that the result will be set **only once**.
- You can call `resume(...)` **before** the actual `CheckedContinuation` is known.
  Later, when `set(continuation:)` is called, the result will be immediately forwarded to the real continuation.
- If `set(continuation:)` is called first, then `resume(...)` will be forwarded immediately.
- On `deinit` (if not yet resumed), resumes with `EZContinuationError.wasDeinit`.

**Example (resume before set):**
```swift
let safe = EZSafeContinuation<Int>()
safe.resume(returning: 1)

// later, when CheckedContinuation is available:
await withCheckedThrowingContinuation { (c: CheckedContinuation<Int, Error>) in
    safe.set(continuation: c) // resumes immediately with 1
}
```

**Example (set before resume):**
```swift
let safe = EZSafeContinuation<Int>()

let value = try await withCheckedThrowingContinuation { (c: CheckedContinuation<Int, Error>) in
    safe.set(continuation: c)
    safe.resume(returning: 5)
}
print(value) // 5
```
