# MainActor.ezUnsafeRun

`MainActor.ezUnsafeRun` — это утилита для **синхронного** выполнения замыкания, помеченного `@MainActor`,
из `nonisolated` контекста **без перехода на MainActor executor**.

> ⚠️ Важно: это **unsafe** API. Оно использует `unsafeBitCast` и намеренно обходится без actor-hop.  
> Это удобно для низкоуровневых оптимизаций/интеграций, но требует осторожности.

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

## Поведение

- Выполняет `action` **синхронно**, возвращая `Result` (или пробрасывая `throw`).
- **Не гарантирует**, что вызов реально происходит на MainActor executor.
- Никакого `await`/планирования на акторе не происходит — это прямой вызов после `unsafeBitCast`.

Используй этот метод только если ты **уверен**, что вызываешь его в корректном месте
(например, ты уже находишься на main thread/executor, либо тебе не важна изоляция, и ты понимаешь риски).

---

## Примеры

### 1) Синхронно получить значение из `@MainActor` контекста

```swift
@MainActor func currentTitle() -> String { "Hello" }

let title = MainActor.ezUnsafeRun {
    currentTitle()
}

print(title)
```

### 2) Вариант с `throws`

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
