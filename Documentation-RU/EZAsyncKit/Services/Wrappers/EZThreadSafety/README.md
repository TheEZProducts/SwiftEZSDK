# EZThreadSafety

`EZThreadSafety` — это `@propertyWrapper`, который даёт потокобезопасный доступ к изменяемому значению
через `get / set / update`. Он рассчитан на **два режима** использования: синхронный и асинхронный.

Ключевая идея реализации:

- **Синхронизация всегда завязана на `DispatchSemaphore`**.
- На платформах с Swift Concurrency (macOS 10.15+, iOS 13+ и т.д.) асинхронные операции дополнительно
  выполняются **в изоляции `actor`**, поэтому **если ты используешь только async-API**, семафор фактически
  не конкурирует (захватывается сразу).
- Семафор нужен в первую очередь, чтобы корректно синхронизировать **пересечение sync и async режимов**
  (когда синхронные `update/get/set` вызываются одновременно с асинхронными).

---

## API

```swift
@propertyWrapper
public struct EZThreadSafety<Value: Sendable>: Sendable {
    public var wrappedValue: Value { get set } // noasync (не использовать в async)
    public var projectedValue: EZThreadSafety<Value> { get }

    // Async API (рекомендуемый в async-коде)
    public func update<Result: Sendable>(
        _ closure: @Sendable (inout Value) throws -> Result
    ) async rethrows -> Result
    public func get() async -> Value
    public func set(_ value: Value) async

    // Sync API (для не-async контекста)
    public func update<Result>(
        _ closure: @Sendable (inout Value) throws -> Result
    ) rethrows -> Result
    public func get() -> Value
    public func set(_ value: Value)

    // wrappedValue помечен как noasync, чтобы не использовать его в async-коде
}
```

---

## Поведение

- Все операции (`get/set/update`) атомарны относительно друг друга.
- **Async режим:** вызовы `await $property.update/get/set` выполняются в изоляции `actor`.
  Между async-вызовами нет гонок, а семафор обычно не блокирует (нет конкуренции).
- **Sync режим:** вызовы `$property.update/get/set` (без `await`) защищены семафором и могут безопасно
  вызываться из любого потока.
- **Смешанный режим:** когда sync и async операции идут параллельно, семафор обеспечивает корректную
  взаимную блокировку между ними.

> В `async` коде используй `$property` и `await`. Прямой доступ через `wrappedValue` помечен как `noasync`
> и нужен в основном для синхронного окружения.

---

## Примеры

### 1) Чистый async (актор даёт изоляцию)

```swift
struct Metrics: Sendable {
    @EZThreadSafety var count: Int = 0

    func inc() async {
        await $count.update { $0 += 1 }
    }

    func value() async -> Int {
        await $count.get()
    }
}
```

### 2) Смешанный режим (sync + async)

```swift
final class Store: @unchecked Sendable {
    @EZThreadSafety var items: [Int] = []

    // async путь
    func addAsync(_ x: Int) async {
        await $items.update { $0.append(x) }
    }

    // sync путь (например, из не-async кода)
    func countSync() -> Int {
        $items.get().count
    }
}
```
