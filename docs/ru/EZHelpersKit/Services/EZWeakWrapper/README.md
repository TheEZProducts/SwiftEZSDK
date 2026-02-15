# EZWeakWrapper

`EZWeakWrapper` — лёгкая обёртка над `weak` ссылкой на объект.

Используется, когда нужно:
- хранить **слабую ссылку** в структуре;
- (опционально) иметь возможность передавать обёртку между задачами, если сам объект `Sendable`.

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+ (как часть пакета утилит)

---

## API

```swift
public struct EZWeakWrapper<Value: AnyObject> {
    public private(set) weak var value: Value?
    public init(value: Value?)
}

extension EZWeakWrapper: Sendable where Value: Sendable {}
```

---

## Поведение

- `value` хранится как `weak`, поэтому автоматически становится `nil`, когда объект деинициализируется.
- `value` доступен только для чтения снаружи (`private(set)`).
- `EZWeakWrapper` становится `Sendable` только если `Value: Sendable`.

---

## Примеры

### 1) Хранение слабой ссылки

```swift
final class Owner {}

var owner: Owner? = Owner()
let weakRef = EZWeakWrapper(value: owner)

print(weakRef.value != nil) // true

owner = nil
print(weakRef.value == nil) // true
```

### 2) Использование в коллекциях

```swift
final class Listener {}
var listeners: [EZWeakWrapper<Listener>] = []

let l = Listener()
listeners.append(.init(value: l))
```
