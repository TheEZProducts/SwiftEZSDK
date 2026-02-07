# EZDeinitAnchor

`EZDeinitAnchor` is an "anchor" that executes a specified action upon deinitialization.

The primary use case is to tie a cleanup action to an object's lifecycle:
cancelling a `Task`, calling `finish()` on an `AsyncStream.Continuation`, releasing resources, etc.

- The action is guaranteed to execute **exactly once** (even if triggered manually).
- `performAction()` allows you to execute the action early, without waiting for `deinit`.
- (Optionally) you can attach the anchor to an `AnyObject` via associated storage (`EZAssociatedKit`).

> Availability: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+
> `ezSnapToObject` is only available when `canImport(EZAssociatedKit) && canImport(ObjectiveC)`.

---

## API

```swift
public final class EZDeinitAnchor: Sendable {
    public init(deinitAction: @Sendable @escaping () -> Void)
    public func performAction()
}
```

### Optional API (EZAssociatedKit + ObjectiveC)

```swift
extension EZDeinitAnchor {
    @discardableResult
    public func ezSnapToObject(_ object: AnyObject) -> Self
}
```

---

## Behavior

- Calls `performAction()` on `deinit`.
- `performAction()`:
  - executes `deinitAction`;
  - then replaces the action with an empty `{}` -- so subsequent calls do nothing.
- `ezSnapToObject(_:)` retains the anchor via the object's associated storage:
  - as long as the object is alive, the anchor is alive;
  - when the object is deinitialized, the anchor is released and the action is executed.

---

## Examples

### 1) Manual storage and early cleanup

```swift
final class ResourceOwner {
    private var anchor: EZDeinitAnchor?

    func start() {
        anchor = EZDeinitAnchor {
            print("cleanup")
        }
    }

    func stop() {
        anchor?.performAction() // run cleanup immediately
        anchor = nil
    }
}
```

### 2) Automatic cleanup on deinitialization

```swift
final class Owner {
    private let anchor: EZDeinitAnchor

    init() {
        anchor = EZDeinitAnchor {
            print("Owner deinit -> cleanup")
        }
    }
}
```

### 3) Attaching to an object (requires EZAssociatedKit + ObjectiveC)

```swift
final class Controller: NSObject {
    func start() {
        EZDeinitAnchor {
            print("Controller deinit -> cleanup")
        }
        .ezSnapToObject(self)
    }
}
```
