# EZActorWrapper

`EZActorWrapper` — простой `actor`, который хранит значение и предоставляет безопасный доступ к нему
через методы `get / set / update`.

Подходит, когда нужно:
- хранить изменяемое состояние и гарантировать сериализацию доступа;
- обновлять значение атомарно через `update { inout ... }`.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## API

```swift
public actor EZActorWrapper<Value> {
    public init(value: Value)

    public func get() -> Value
    public func set(_ value: Value)

    @discardableResult
    public func update<Result>(
        _ action: (inout Value) throws -> Result
    ) rethrows -> Result
}
```

---

## Поведение

- Все обращения к `value` выполняются **в изоляции актора** (сериализовано).
- `update` позволяет изменить значение и вернуть результат в рамках одной операции.

---

## Примеры

### 1) Хранение состояния

```swift
let state = EZActorWrapper(value: 0)

await state.set(10)
let v = await state.get()
print(v) // 10
```

### 2) Атомарное обновление через `update`

```swift
let counter = EZActorWrapper(value: 0)

let newValue = try await counter.update { value in
    value += 1
    return value
}

print(newValue) // 1
```
