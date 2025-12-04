# EZAsyncValue

`EZAsyncValue` — это одноразовый контейнер для результата, который будет доступен **позже** через `await`.
По смыслу близок к “promise / future”: значение (или ошибка) устанавливается один раз, а читать его можно сколько угодно раз.

- `get()` ждёт, пока результат будет установлен, затем возвращает значение или бросает ошибку.
- Результат устанавливается **один раз** через `EZActionContinuation` (повторные установки игнорируются).
- Если continuation будет деинициализирован до резюма — `get()` получит ошибку `EZContinuationError.wasDeinit`.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
public final class EZAsyncValue<Value: Sendable>: Sendable {
    public init(action: (EZActionContinuation<Value>) -> Void)
    public func get() async throws -> Value

    public static func makeValue()
      -> (value: EZAsyncValue, continuation: EZActionContinuation<Value>)
}

public final class EZActionContinuation<T: Sendable>: Sendable {
    public func resume(with result: Result<T, Error>)
    public func resume(returning value: T)
    public func resume(throwing error: Error)
}
```

---

## Поведение

- **Ожидание:** `get()` при отсутствии результата приостанавливается до тех пор, пока continuation не будет `resume(...)`.
- **Кеширование:** после установки результата `get()` возвращает его сразу (без ожидания).
- **Одна установка:** результат фиксируется только при первой установке; последующие `resume(...)` не меняют состояние.
- **Много читателей:** несколько задач могут одновременно ждать `get()` — все будут разбужены одним `resume(...)`.
- **Ошибки:** если установлен `.failure`, все `get()` будут бросать этот `Error`.

---

## Примеры использования

### 1) Один продюсер — много потребителей

```swift
enum MyError: Error { case failed }

let asyncValue = EZAsyncValue<Int> { continuation in
    Task.detached {
        // имитация асинхронной работы
        try? await Task.sleep(nanoseconds: 300_000_000)
        continuation.resume(returning: 42)
        // continuation.resume(throwing: MyError.failed) // альтернативно: ошибка
    }
}

// Несколько задач могут ждать один и тот же результат
for id in 1...3 {
    Task {
        do {
            let v = try await asyncValue.get()
            print("consumer \(id):", v)
        } catch {
            print("consumer \(id) error:", error)
        }
    }
}
```

### 2) Ручная связка через `makeValue()`

```swift
let (value, continuation) = EZAsyncValue<String>.makeValue()

Task {
    do {
        print("result:", try await value.get())
    } catch {
        print("error:", error)
    }
}

Task.detached {
    continuation.resume(returning: "done")
    // continuation.resume(throwing: SomeError()) // если нужно завершить ошибкой
}
```
