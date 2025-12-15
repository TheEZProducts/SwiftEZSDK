# EZAsyncValue

`EZAsyncValue` — асинхронное значение (`actor`), которое можно ожидать из многих задач и завершать через continuation.
По смыслу близко к “promise / future”: значение (или ошибка) устанавливается через `EZActionContinuation`, а читатели получают его через `await get()`.

Типичная сфера применения:
- мост от callback-API к `async/await`;
- разделяемое "promise-подобное" значение между несколькими задачами;
- опциональные **обновления значения во времени** через один и тот же контейнер (`isAbleToUpdating`).

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

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

## Поведение

- **Ожидание:** `get()` при отсутствии результата приостанавливается до тех пор, пока continuation не будет `resume(...)`. Перед этим вызывается `Task.checkCancellation()`, поэтому отменённая задача завершится `CancellationError`.
- **Кеширование:** после установки результата `get()` возвращает его сразу, без повторной приостановки.
- **Много читателей:** несколько задач могут одновременно ждать `get()` — все текущие ожидающие будут разбужены одним `resume(...)`.
- **Ошибки:** если установлен `.failure`, все `get()` будут бросать соответствующий `Error`.
- **Режим по умолчанию (`isAbleToUpdating == false`):**
  - continuation ведёт себя как one-shot;
  - первая успешная/ошибочная завершёнка будит всех текущих ожидающих и фиксирует результат внутри `EZAsyncValue`;
  - последующие вызовы `resume(...)` игнорируются.
- **Режим обновлений (`isAbleToUpdating == true`):**
  - continuation становится переиспользуемым (`isReusable = true`);
  - каждый новый `resume(...)` обновляет сохранённый `result` внутри `EZAsyncValue`;
  - задачи, которые вызывают `get()` **после** очередного обновления, сразу получают последнюю версию значения/ошибки;
  - уже отработавшие `get()` повторно не уведомляются автоматически — для нового чтения нужно снова вызвать `get()`.

---

## Примеры использования

### 1) Мост из completion-handler (one-shot)

```swift
func fetchNumber(completion: @escaping (Result<Int, Error>) -> Void) {
    // ... любая callback-реализация
}

let asyncValue = EZAsyncValue<Int> { continuation in
    fetchNumber { result in
        continuation.resume(with: result)
    }
}

let number = try await asyncValue.get()
```

---

### 2) Обновляемое значение (`isAbleToUpdating`)

```swift
let value = EZAsyncValue<Int>(isAbleToUpdating: true) { continuation in
    continuation.resume(returning: 1)
    continuation.resume(returning: 2) // перезаписывает сохранённый результат
}

// Позже, в другой задаче:
let latest = try await value.get() // 2
```

---

### 3) Использование `makeValue`

```swift
let (value, continuation) = EZAsyncValue<Int>.makeValue()

Task {
    // где-то позже
    continuation.resume(returning: 42)
}

let answer = try await value.get() // 42
```
