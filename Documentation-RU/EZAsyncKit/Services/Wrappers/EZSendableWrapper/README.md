# Sendable wrappers

Два небольших типа для упрощения работы с `Sendable` и конкурентным доступом:

- `EZUnsafeSendableWrapper` — обёртка `@unchecked Sendable` для значения, когда ты **сам берёшь на себя ответственность** за потокобезопасность.
- `EZSendableWrapper` — `@propertyWrapper`, который делает доступ к значению потокобезопасным через семафор и при этом остаётся `Sendable`.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## EZUnsafeSendableWrapper

```swift
public struct EZUnsafeSendableWrapper<Value>: @unchecked Sendable {
    public var value: Value
    public init(_ value: Value)
}
```

- Помечает значение как `@unchecked Sendable`.
- **Не добавляет синхронизацию.** Это просто “я знаю что делаю”.

**Пример:**
```swift
let op = EZUnsafeSendableWrapper { (x: Int) -> Int in x + 1 }
// op.value можно передавать туда, где требуется Sendable, но безопасность — на тебе
```

---

## EZSendableWrapper

```swift
@propertyWrapper
public final class EZSendableWrapper<T>: Sendable {
    public var wrappedValue: T { get set }
    public var projectedValue: EZSendableWrapper<T> { get }

    public init(wrappedValue: T)

    public func get() -> T
    public func set(_ value: T)

    @discardableResult
    public func update<R>(_ closure: (inout T) throws -> R) rethrows -> R
}
```

`EZSendableWrapper` хранит значение и защищает любые чтения/записи через `DispatchSemaphore`.

- `wrappedValue`: удобный доступ (внутри использует `get()/set()`).
- `$property.update { ... }`: атомарная операция “прочитать/изменить/вернуть” внутри одной критической секции.

**Пример:**
```swift
struct State: Sendable {
    @EZSendableWrapper var count: Int = 0

    func inc() {
        $count.update { $0 += 1 }
    }

    func value() -> Int {
        $count.get()
    }
}
```

**Пример с атомарным обновлением и возвратом результата:**
```swift
@EZSendableWrapper var items: [Int] = []

let newCount = $items.update { items in
    items.append(1)
    return items.count
}
print(newCount)
```
