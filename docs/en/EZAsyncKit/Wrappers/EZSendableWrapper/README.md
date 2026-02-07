# Sendable wrappers

Small helpers for simplifying value passing across concurrency boundaries (`Sendable` and Swift Concurrency):

- `EZUnsafeSendableWrapper` -- an **@unchecked Sendable** wrapper for a value when you **take responsibility yourself** for thread safety.
- `EZSendableWrapper` -- a `@propertyWrapper` that serializes access to the value through `EZRecursiveMutex` from `EZHelpersKit`.

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+

---

## EZUnsafeSendableWrapper

```swift
public struct EZUnsafeSendableWrapper<Value>: @unchecked Sendable {
    public var value: Value
    public init(_ value: Value)
}
```

- Marks the value as `@unchecked Sendable`.
- **Does not add synchronization.** Use only if:
  - the value is inherently thread-safe (e.g. an immutable value type), or
  - you ensure correct synchronization externally.

**Example:**
```swift
let box = EZUnsafeSendableWrapper([1, 2, 3])
// You are responsible for safe access to box.value.
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

    // Read/write under lock
    public func get() -> T where T: Copyable
    public func set(_ value: consuming T)

    // Deprecated: inout access to the value
    @available(*, deprecated, message: "Use update(_ closure: (borrowing EZAccess<T>) throws -> R) instead")
    @discardableResult
    public func update<R>(_ closure: (inout T) throws -> R) rethrows -> R where R: ~Copyable

    // Recommended: via EZAccess<T>, works well with non-copyable types
    @discardableResult
    public func update<R>(_ closure: (borrowing EZAccess<T>) throws -> R) rethrows -> R where R: ~Copyable
}
```

`EZSendableWrapper` stores the value inside `EZRecursiveMutex<T>` and serializes **all** `get / set / update` operations.

- `wrappedValue` -- convenient access to the value. For complex mutations, it is better to use `update(_:)` so the entire operation is atomic.
- `$property.update { ... }` executes the provided block under a lock:
  - gives either direct `inout` (deprecated API),
  - or `EZAccess<T>`, which is convenient to use with non-copyable values.

### Recommended usage style

**Simple counter:**
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

**Atomic update with return value:**
```swift
@EZSendableWrapper var items: [Int] = []

let newCount = $items.update { access in
    access.value.append(1)
    return access.value.count
}

print(newCount)
```

### API notes

- For **reading** in synchronous code, you can use:
  - `wrappedValue` (standard getter),
  - or `$property.get()` (explicit call under lock).
- For **writing**:
  - `wrappedValue = newValue`,
  - or `$property.set(newValue)`.
- For **read-modify-write**, always prefer `update(_:)` to avoid races and ensure that the entire operation is performed under a single lock.
