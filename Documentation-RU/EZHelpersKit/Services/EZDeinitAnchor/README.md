# EZDeinitAnchor

`EZDeinitAnchor` — это “якорь”, который выполняет заданное действие при деинициализации.

Основной сценарий — привязать какое-то cleanup-действие к жизненному циклу объекта:
отмена `Task`, `finish()` у `AsyncStream.Continuation`, освобождение ресурсов и т.п.

- Действие гарантированно выполняется **один раз** (даже если вызвать вручную).
- `performAction()` позволяет выполнить действие раньше, не дожидаясь `deinit`.
- (Опционально) можно “прикрепить” якорь к `AnyObject` через associated storage (`EZAssociatedKit`).

> Доступность: macOS 10.15+, iOS 13+, watchOS 6+, tvOS 13+  
> `ezSnapToObject` доступен только при `canImport(EZAssociatedKit) && canImport(ObjectiveC)`.

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

## Поведение

- При `deinit` вызывает `performAction()`.
- `performAction()`:
  - выполняет `deinitAction`;
  - затем заменяет действие на пустое `{}` — поэтому повторные вызовы ничего не делают.
- `ezSnapToObject(_:)` удерживает якорь через associated storage объекта:
  - пока объект жив — якорь жив;
  - при деинициализации объекта якорь освобождается и выполняет действие.

---

## Примеры

### 1) Ручное хранение и ранний cleanup

```swift
final class ResourceOwner {
    private var anchor: EZDeinitAnchor?

    func start() {
        anchor = EZDeinitAnchor {
            print("cleanup")
        }
    }

    func stop() {
        anchor?.performAction() // выполняем cleanup сразу
        anchor = nil
    }
}
```

### 2) Автоматический cleanup при деинициализации

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

### 3) Привязка к объекту (только при EZAssociatedKit + ObjectiveC)

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
