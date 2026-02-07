# EZActorWrapper

`EZActorWrapper` is a simple `actor` that stores a value and provides safe access to it
via `get / set / update` methods.

Useful when you need to:
- store mutable state and guarantee serialized access;
- update the value atomically via `update { inout ... }`.

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

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

## Behavior

- All accesses to `value` are performed **within the actor's isolation** (serialized).
- `update` lets you modify the value and return a result within a single operation.

---

## Examples

### 1) Storing state

```swift
let state = EZActorWrapper(value: 0)

await state.set(10)
let v = await state.get()
print(v) // 10
```

### 2) Atomic update via `update`

```swift
let counter = EZActorWrapper(value: 0)

let newValue = try await counter.update { value in
    value += 1
    return value
}

print(newValue) // 1
```
