# Sendable wrappers

Небольшие помощники для упрощения передачи значений через границы конкуренции (`Sendable` и Swift Concurrency):

- `EZUnsafeSendableWrapper` — обёртка **@unchecked Sendable** для значения, когда ты **сам берёшь на себя ответственность** за потокобезопасность.
- `EZSendableWrapper` — `@propertyWrapper`, который сериализует доступ к значению через `EZRecursiveMutex` из `EZHelpersKit`.

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
- **Не добавляет синхронизацию.** Используй только если:
  - значение по сути потокобезопасно (например, неизменяемый value-type), или
  - ты сам обеспечиваешь корректную синхронизацию снаружи.

**Пример:**
```swift
let box = EZUnsafeSendableWrapper([1, 2, 3])
// Ты сам отвечаешь за безопасный доступ к box.value.
```

---

## EZSendableWrapper

```swift
@propertyWrapper
public final class EZSendableWrapper<T>: Sendable {
    public var projectedValue: EZSendableWrapper<T> { get }
    public var wrappedValue: T { get set }

    public init(wrappedValue: consuming T)
    public convenience init(_ value: consuming T)

    // Чтение/запись под локом
    public func get() -> T where T: Copyable
    public func set(_ value: consuming T)

    // Устаревший вариант: inout-доступ к значению
    @available(*, deprecated, message: "Use update(_ closure: (borrowing EZAccess<T>) throws -> R) instead")
    @discardableResult
    public func update<R>(_ closure: (inout T) throws -> R) rethrows -> R where R: ~Copyable

    // Рекомендованный вариант: через EZAccess<T>, хорошо работает с некопируемыми типами
    @discardableResult
    public func update<R>(_ closure: (borrowing EZAccess<T>) throws -> R) rethrows -> R where R: ~Copyable
}
```

`EZSendableWrapper` хранит значение внутри `EZRecursiveMutex<T>` и сериализует **все** операции `get / set / update`.

- `wrappedValue` — удобный доступ к значению. Для сложных мутаций лучше использовать `update(_:)`, чтобы вся операция была атомарной.
- `$property.update { ... }` выполняет переданный блок под локом:
  - даёт либо прямой `inout` (устаревший API),
  - либо `EZAccess<T>`, который удобно использовать с некопируемыми значениями.

### Рекомендуемый стиль использования

**Простой счётчик:**
```swift
final class Counter {
    @EZSendableWrapper var value: Int = 0

    func inc() {
        $value.update { access in
            access.value += 1
        }
    }

    func snapshot() -> Int {
        $value.get()
    }
}
```

**Атомарное обновление с возвратом результата:**
```swift
@EZSendableWrapper var items: [Int] = []

let newCount = $items.update { access in
    access.value.append(1)
    return access.value.count
}

print(newCount)
```

### Замечания по API

- Для **чтения** в синхронном коде можно использовать:
  - `wrappedValue` (обычный геттер),
  - или `$property.get()` (явный вызов под локом).
- Для **записи**:
  - `wrappedValue = newValue`,
  - или `$property.set(newValue)`.
- Для **read–modify–write** всегда предпочитай `update(_:)`, чтобы избежать гонок и гарантировать, что вся операция выполнится под одним локом.
