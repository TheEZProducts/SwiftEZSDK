# EZWeakWrapper

`EZWeakWrapper` is a lightweight wrapper around a `weak` reference to an object.

Useful when you need to:
- store a **weak reference** in a struct;
- (optionally) pass the wrapper between tasks, if the object itself is `Sendable`.

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+ (as part of the utilities package)

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

## Behavior

- `value` is stored as `weak`, so it automatically becomes `nil` when the object is deinitialized.
- `value` is read-only from outside (`private(set)`).
- `EZWeakWrapper` becomes `Sendable` only if `Value: Sendable`.

---

## Examples

### 1) Storing a weak reference

```swift
final class Owner {}

var owner: Owner? = Owner()
let weakRef = EZWeakWrapper(value: owner)

print(weakRef.value != nil) // true

owner = nil
print(weakRef.value == nil) // true
```

### 2) Usage in collections

```swift
final class Listener {}
var listeners: [EZWeakWrapper<Listener>] = []

let l = Listener()
listeners.append(.init(value: l))
```
