# Continuations (EZ*)

Набор базовых типов для унифицированной работы с continuations и безопасного резюма:

- `EZContinuationProtocol` — общий протокол с `resume(returning:) / resume(throwing:)` + удобными хелперами.
- `EZContinuationError` — стандартная ошибка для случая, когда continuation-владелец был деинициализирован.
- `EZActionContinuation` — continuation, который резюмится через async-callback (одноразовый).
- `EZSafeContinuation` — безопасная обёртка вокруг `CheckedContinuation`, которая гарантирует **однократный resume**
  и позволяет резюмить даже если реальный `CheckedContinuation` будет установлен позже.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## EZContinuationError

```swift
public enum EZContinuationError: String, LocalizedError, Sendable {
    case wasDeinit = "Was deallocated"
}
```

Используется как дефолтная ошибка при `deinit`, если continuation не был резюмнут явно.

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

### Хелперы

Доступны удобные перегрузки:
- `resume(with: Result<...>)` (в т.ч. когда `E == any Error`);
- `resume()` для случая `T == ()`.

Также `CheckedContinuation` и `UnsafeContinuation` автоматически соответствуют протоколу:

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

- Одноразовый: после первого `resume(...)` callback очищается.
- Резюм вызывает переданный `action` внутри `Task`.
- Если объект деинициализируется до `resume(...)`, автоматически резюмится ошибкой `EZContinuationError.wasDeinit`.

**Пример:**
```swift
let cont = EZActionContinuation<Int> { result in
    print(result)
}

cont.resume(returning: 10) // печатает success(10)
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

### Поведение

- Гарантирует, что результат будет установлен **только один раз**.
- Можно вызвать `resume(...)` **до** того, как будет известен реальный `CheckedContinuation`.
  Позже, при `set(continuation:)`, результат сразу будет проброшен в реальный continuation.
- Если вызвать `set(continuation:)` первым, то `resume(...)` пробросится сразу.
- На `deinit` (если ещё не резюмнут) резюмится ошибкой `EZContinuationError.wasDeinit`.

**Пример (resume раньше, чем set):**
```swift
let safe = EZSafeContinuation<Int>()
safe.resume(returning: 1)

// позже, когда появился CheckedContinuation:
await withCheckedThrowingContinuation { (c: CheckedContinuation<Int, Error>) in
    safe.set(continuation: c) // сразу зарезюмится 1
}
```

**Пример (set раньше, чем resume):**
```swift
let safe = EZSafeContinuation<Int>()

let value = try await withCheckedThrowingContinuation { (c: CheckedContinuation<Int, Error>) in
    safe.set(continuation: c)
    safe.resume(returning: 5)
}
print(value) // 5
```
