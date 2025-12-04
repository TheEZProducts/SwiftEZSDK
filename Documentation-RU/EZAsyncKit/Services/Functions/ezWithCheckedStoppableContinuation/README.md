# ezWithCheckedStoppableContinuation

`ezWithCheckedStoppableContinuation` — это обёртка над `withCheckedThrowingContinuation`,
которая автоматически **резюмится ошибкой `CancellationError` при отмене текущей задачи**.

Используется для построения API, где нужно “подвеситься” на continuation, но при этом корректно
обрабатывать отмену `Task` (не оставляя continuation висящим навсегда).

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
public func ezWithCheckedStoppableContinuation<Result: Sendable>(
    isolation: isolated (any Actor)? = #isolation,
    _ body: (EZSafeContinuation<Result>) -> Void
) async throws -> Result
```

---

## Поведение

- Создаёт `EZSafeContinuation<Result>` и передаёт её в `body`.
- Возвращает результат через `await`, когда continuation будет `resume(...)`.
- Если текущая задача отменена, функция автоматически резюмится `CancellationError`.
- Параметр `isolation` прокидывается в `withCheckedThrowingContinuation` и `withTaskCancellationHandler`
  (по умолчанию использует `#isolation`).

---

## Пример

Ниже пример превращения callback-API в `async` с корректной отменой:

```swift
func doWork(_ completion: @escaping (Result<Int, Error>) -> Void) {
    // имитация асинхронной операции
    Task.detached {
        try? await Task.sleep(nanoseconds: 500_000_000)
        completion(.success(123))
    }
}

func doWorkAsync() async throws -> Int {
    return try await ezWithCheckedStoppableContinuation { continuation in
        doWork { result in
            continuation.resume(with: result)
        }
    }
    // если внешний Task отменится — continuation получит CancellationError
    // а ты можешь дополнительно отменить исходную операцию через token
}

let task = Task {
    do {
        let value = try await doWorkAsync()
        print(value)
    } catch is CancellationError {
        print("cancelled")
    } catch {
        print("error:", error)
    }
}

try? await Task.sleep(nanoseconds: 300_000_000)
task.cancel()
```

> Если у твоего callback-API есть свой cancel-токен, обычно его стоит дернуть при отмене задачи
> (например, через `withTaskCancellationHandler` рядом), но базовую “стопаемость” continuation
> эта функция уже гарантирует.
