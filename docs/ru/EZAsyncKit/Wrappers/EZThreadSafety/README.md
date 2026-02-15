# EZThreadSafety

`EZThreadSafety` — это `@propertyWrapper`, который даёт потокобезопасный доступ к изменяемому значению
через `get / set / update`. Он рассчитан на **два режима** использования: синхронный и асинхронный.

Ключевая идея реализации:

- В синхронном режиме (`$value.get()/set()/update()` без `await`) всё сериализуется через `EZRecursiveMutex` из `EZHelpersKit`.
- В асинхронном режиме (`await $value.get()/set()/update()`) основную изоляцию даёт `actor` (`ActorIsolatedValue`): все async-обращения заходят последовательно.
- Тот же `EZRecursiveMutex` дополнительно прикрывает доступ из async-кода, чтобы не было гонок, если параллельно идут синхронные вызовы.
- На старых системах без `async/await` используется `EZSendableWrapper`, который тоже основан на `EZRecursiveMutex`, поэтому sync-доступ остаётся потокобезопасным.

---

## API

```swift
@propertyWrapper
public struct EZThreadSafety<Value: Sendable>: Sendable {
    public var wrappedValue: Value { get set } // noasync (не использовать в async)
    public var projectedValue: EZThreadSafety<Value> { get }

    // Async API (рекомендуемый в async-коде)

    /// Устаревший вариант: inout-доступ к значению.
    @available(*, deprecated,
               message: "Use update(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> R) async rethrows -> R instead")
    public func update<R: Sendable>(
        _ closure: @Sendable (inout Value) throws -> R
    ) async rethrows -> R

    /// Предпочтительный вариант: через EZAccess<Value>, хорошо работает с некопируемыми значениями.
    public func update<R: Sendable>(
        _ closure: @Sendable (borrowing EZAccess<Value>) throws -> R
    ) async rethrows -> R where R: ~Copyable

    public func get() async -> Value
    public func set(_ value: Value) async

    // Sync API (для не-async контекста)

    /// Устаревший вариант: inout-доступ к значению.
    @available(*, deprecated,
               message: "Use update(_ closure: @Sendable (borrowing EZAccess<Value>) throws -> R) instead")
    public func update<R>(
        _ closure: @Sendable (inout Value) throws -> R
    ) rethrows -> R

    /// Предпочтительный sync-вариант: через EZAccess<Value>.
    public func update<R>(
        _ closure: @Sendable (borrowing EZAccess<Value>) throws -> R
    ) rethrows -> R where R: ~Copyable

    public func get() -> Value
    public func set(_ value: Value)

    public init(wrappedValue: Value)
    public init(_ value: Value)
}
```

---

## Поведение

- Все операции (`get/set/update`) атомарны относительно друг друга: каждое обращение полностью выполняется до начала следующего.
- **Async режим:**
  - `await $property.update/get/set` заходят на `ActorIsolatedValue`, поэтому сами по себе async-вызовы выполняются последовательно (актерная изоляция).
  - внутри актора доступ к данным дополнительно проходит через `EZRecursiveMutex`, чтобы не конфликтовать с возможными синхронными обращениями.
- **Sync режим:**
  - `$property.update/get/set` (без `await`) работают поверх `EZRecursiveMutex` (через `EZSendableWrapper` или ту же mutex-базу),
  - их безопасно вызывать с любого потока, они просто берут лок и выполняют переданный блок.
- **Смешанный режим (sync + async):**
  - async-код сериализуется актором, sync-код — мутексом,
  - оба режима используют один и тот же `EZRecursiveMutex` для самого значения, поэтому гонок между sync и async доступом нет.

> В `async` коде используй `$property` и `await`. Прямой доступ через `wrappedValue` помечен как `noasync`
> и нужен в основном для синхронного окружения.

---

## Примеры

### 1) Чистый async (актор даёт изоляцию)

```swift
struct Metrics: Sendable {
    @EZThreadSafety var count: Int = 0

    func inc() async {
        await $count.update { access in
            access.value += 1
        }
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
        await $items.update { access in
            access.value.append(x)
        }
    }

    // sync путь (например, из не-async кода)
    func countSync() -> Int {
        $items.get().count
    }
}
```
